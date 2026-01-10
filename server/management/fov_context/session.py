"""
FOV Session Management - Server-side session state with FOV context

Manages session lifecycle and integrates FOV context for voice tutoring.
"""

import logging
import uuid
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from typing import Any, Optional

from .confidence import ConfidenceAnalysis, ConfidenceMonitor, ExpansionRecommendation
from .manager import FOVContextManager
from .models import (
    AdaptiveBudgetConfig,
    ConversationTurn,
    CurriculumPosition,
    FOVContext,
    GlossaryTerm,
    MessageRole,
    MisconceptionTrigger,
    TopicSummary,
    TranscriptSegment,
)

logger = logging.getLogger(__name__)


class SessionState(str, Enum):
    """State of a voice tutoring session."""
    IDLE = "idle"
    PLAYING = "playing"           # Playing curriculum content
    USER_SPEAKING = "user_speaking"
    AI_THINKING = "ai_thinking"
    AI_SPEAKING = "ai_speaking"
    PAUSED = "paused"
    ENDED = "ended"


@dataclass
class SessionConfig:
    """Configuration for a session."""
    model_name: str = "claude-3-5-sonnet-20241022"
    model_context_window: int = 200_000
    system_prompt: Optional[str] = None
    auto_expand_context: bool = True
    confidence_threshold: float = 0.5


@dataclass
class SessionEvent:
    """An event that occurred during the session."""
    event_type: str
    timestamp: datetime = field(default_factory=datetime.now)
    data: dict = field(default_factory=dict)


@dataclass
class FOVSession:
    """
    A voice tutoring session with FOV context management.

    Maintains:
    - Session state and lifecycle
    - FOV context manager for LLM calls
    - Confidence monitoring for auto-expansion
    - Curriculum position and progress
    - Conversation history
    """

    session_id: str
    curriculum_id: str
    config: SessionConfig
    context_manager: FOVContextManager
    confidence_monitor: ConfidenceMonitor = field(default_factory=ConfidenceMonitor)

    # State
    state: SessionState = SessionState.IDLE
    current_topic_id: Optional[str] = None
    current_segment: Optional[TranscriptSegment] = None

    # Timing
    created_at: datetime = field(default_factory=datetime.now)
    started_at: Optional[datetime] = None
    ended_at: Optional[datetime] = None

    # Conversation
    conversation_history: list[ConversationTurn] = field(default_factory=list)
    events: list[SessionEvent] = field(default_factory=list)

    # Metrics
    total_turns: int = 0
    barge_in_count: int = 0
    expansion_count: int = 0

    @classmethod
    def create(
        cls,
        curriculum_id: str,
        config: Optional[SessionConfig] = None
    ) -> "FOVSession":
        """Create a new session."""
        config = config or SessionConfig()

        context_manager = FOVContextManager.for_context_window(
            config.model_context_window,
            config.system_prompt
        )

        session = cls(
            session_id=str(uuid.uuid4()),
            curriculum_id=curriculum_id,
            config=config,
            context_manager=context_manager
        )

        session._log_event("session_created", {"curriculum_id": curriculum_id})
        logger.info(f"Created session {session.session_id} for curriculum {curriculum_id}")

        return session

    # --- Lifecycle ---

    def start(self) -> None:
        """Start the session."""
        self.state = SessionState.PLAYING
        self.started_at = datetime.now()
        self._log_event("session_started")
        logger.info(f"Session {self.session_id} started")

    def pause(self) -> None:
        """Pause the session."""
        self.state = SessionState.PAUSED
        self._log_event("session_paused")

    def resume(self) -> None:
        """Resume the session."""
        self.state = SessionState.PLAYING
        self._log_event("session_resumed")

    def end(self) -> None:
        """End the session."""
        self.state = SessionState.ENDED
        self.ended_at = datetime.now()
        self._log_event("session_ended")
        logger.info(f"Session {self.session_id} ended")

    # --- Curriculum Context ---

    def set_current_topic(
        self,
        topic_id: str,
        topic_title: str,
        topic_content: str,
        learning_objectives: list[str],
        glossary_terms: Optional[list[dict]] = None,
        misconceptions: Optional[list[dict]] = None
    ) -> None:
        """Set the current topic being taught."""
        self.current_topic_id = topic_id

        # Convert dicts to dataclasses if needed
        glossary = [
            GlossaryTerm(**t) if isinstance(t, dict) else t
            for t in (glossary_terms or [])
        ]
        triggers = [
            MisconceptionTrigger(**m) if isinstance(m, dict) else m
            for m in (misconceptions or [])
        ]

        self.context_manager.set_current_topic(
            topic_id=topic_id,
            topic_title=topic_title,
            topic_content=topic_content,
            learning_objectives=learning_objectives,
            glossary_terms=glossary,
            misconception_triggers=triggers
        )

        self._log_event("topic_changed", {"topic_id": topic_id, "title": topic_title})

    def set_curriculum_position(
        self,
        curriculum_title: str,
        current_topic_index: int,
        total_topics: int,
        unit_title: Optional[str] = None,
        curriculum_outline: Optional[str] = None
    ) -> None:
        """Set the current position in the curriculum."""
        self.context_manager.set_curriculum_position(
            curriculum_id=self.curriculum_id,
            curriculum_title=curriculum_title,
            current_topic_index=current_topic_index,
            total_topics=total_topics,
            unit_title=unit_title
        )

        if curriculum_outline:
            self.context_manager.update_semantic_buffer(
                curriculum_outline=curriculum_outline
            )

    def set_current_segment(self, segment: TranscriptSegment) -> None:
        """Set the current transcript segment being played."""
        self.current_segment = segment
        self.context_manager.set_current_segment(segment)

    # --- Conversation ---

    def add_user_turn(self, content: str, is_barge_in: bool = False) -> ConversationTurn:
        """Add a user turn to the conversation."""
        turn = ConversationTurn(
            role=MessageRole.USER,
            content=content,
            is_barge_in=is_barge_in
        )

        self.conversation_history.append(turn)
        self.context_manager.add_conversation_turn(turn)
        self.total_turns += 1

        if is_barge_in:
            self.barge_in_count += 1
            self.context_manager.record_barge_in(content)
            self._log_event("barge_in", {"content": content[:100]})
        else:
            self._log_event("user_turn", {"content": content[:100]})

        return turn

    def add_assistant_turn(self, content: str) -> ConversationTurn:
        """Add an assistant turn to the conversation."""
        turn = ConversationTurn(
            role=MessageRole.ASSISTANT,
            content=content
        )

        self.conversation_history.append(turn)
        self.context_manager.add_conversation_turn(turn)
        self.total_turns += 1

        self._log_event("assistant_turn", {"content": content[:100]})

        return turn

    # --- Context Building ---

    def build_llm_context(
        self,
        barge_in_utterance: Optional[str] = None
    ) -> FOVContext:
        """
        Build the foveated context for an LLM call.

        Returns the complete context with all buffer layers.
        """
        self.context_manager.update_session_duration()

        context = self.context_manager.build_context(
            conversation_history=self.conversation_history,
            barge_in_utterance=barge_in_utterance
        )

        return context

    def build_llm_messages(
        self,
        barge_in_utterance: Optional[str] = None
    ) -> list[dict]:
        """
        Build the complete message list for an LLM call.

        Returns list of messages ready for the LLM API.
        """
        self.context_manager.update_session_duration()

        messages = self.context_manager.build_messages_for_llm(
            conversation_history=self.conversation_history,
            barge_in_utterance=barge_in_utterance
        )

        return messages

    # --- Confidence Analysis ---

    def analyze_response(self, response: str) -> ConfidenceAnalysis:
        """Analyze an LLM response for confidence signals."""
        analysis = self.confidence_monitor.analyze_response(response)

        self._log_event("confidence_analysis", {
            "confidence": analysis.confidence_score,
            "markers": [m.value for m in analysis.detected_markers],
            "trend": analysis.trend.value
        })

        return analysis

    def get_expansion_recommendation(
        self,
        analysis: ConfidenceAnalysis
    ) -> ExpansionRecommendation:
        """Get recommendation for context expansion."""
        recommendation = self.confidence_monitor.get_expansion_recommendation(analysis)

        if recommendation.should_expand:
            self.expansion_count += 1
            self._log_event("expansion_recommended", {
                "priority": recommendation.priority.value,
                "scope": recommendation.suggested_scope.value,
                "reason": recommendation.reason
            })

        return recommendation

    def process_response_with_confidence(
        self,
        response: str
    ) -> tuple[ConfidenceAnalysis, Optional[ExpansionRecommendation]]:
        """
        Process an LLM response with confidence monitoring.

        Returns the analysis and expansion recommendation if auto-expand is enabled.
        """
        analysis = self.analyze_response(response)

        recommendation = None
        if self.config.auto_expand_context:
            recommendation = self.get_expansion_recommendation(analysis)

        return analysis, recommendation

    # --- Learner Signals ---

    def record_clarification_request(self) -> None:
        """Record that the user requested clarification."""
        self.context_manager.record_clarification_request()
        self._log_event("clarification_request")

    def record_repetition_request(self) -> None:
        """Record that the user requested repetition."""
        self.context_manager.record_repetition_request()
        self._log_event("repetition_request")

    def record_confusion_signal(self) -> None:
        """Record a confusion indicator."""
        self.context_manager.record_confusion_signal()
        self._log_event("confusion_signal")

    def record_topic_completion(
        self,
        summary: str,
        mastery_level: float
    ) -> None:
        """Record completion of the current topic."""
        if not self.current_topic_id:
            return

        topic_summary = TopicSummary(
            topic_id=self.current_topic_id,
            title=self.context_manager.working_buffer.topic_title,
            summary=summary,
            mastery_level=mastery_level
        )

        self.context_manager.record_topic_completion(topic_summary)
        self._log_event("topic_completed", {
            "topic_id": self.current_topic_id,
            "mastery": mastery_level
        })

    # --- State Export ---

    def get_state(self) -> dict:
        """Get the current session state."""
        duration = 0.0
        if self.started_at:
            end = self.ended_at or datetime.now()
            duration = (end - self.started_at).total_seconds() / 60

        return {
            "session_id": self.session_id,
            "curriculum_id": self.curriculum_id,
            "state": self.state.value,
            "current_topic_id": self.current_topic_id,
            "created_at": self.created_at.isoformat(),
            "started_at": self.started_at.isoformat() if self.started_at else None,
            "ended_at": self.ended_at.isoformat() if self.ended_at else None,
            "duration_minutes": duration,
            "total_turns": self.total_turns,
            "barge_in_count": self.barge_in_count,
            "expansion_count": self.expansion_count,
            "context_state": self.context_manager.get_state_snapshot()
        }

    def get_events(self, event_type: Optional[str] = None) -> list[dict]:
        """Get session events, optionally filtered by type."""
        events = self.events
        if event_type:
            events = [e for e in events if e.event_type == event_type]

        return [
            {
                "type": e.event_type,
                "timestamp": e.timestamp.isoformat(),
                "data": e.data
            }
            for e in events
        ]

    # --- Private Methods ---

    def _log_event(self, event_type: str, data: Optional[dict] = None) -> None:
        """Log a session event."""
        event = SessionEvent(
            event_type=event_type,
            data=data or {}
        )
        self.events.append(event)


class SessionManager:
    """
    Manages multiple FOV sessions.

    Provides session lifecycle management and lookup.
    """

    def __init__(self):
        self._sessions: dict[str, FOVSession] = {}

    def create_session(
        self,
        curriculum_id: str,
        config: Optional[SessionConfig] = None
    ) -> FOVSession:
        """Create a new session."""
        session = FOVSession.create(curriculum_id, config)
        self._sessions[session.session_id] = session
        return session

    def get_session(self, session_id: str) -> Optional[FOVSession]:
        """Get a session by ID."""
        return self._sessions.get(session_id)

    def end_session(self, session_id: str) -> bool:
        """End and remove a session."""
        session = self._sessions.get(session_id)
        if session:
            session.end()
            del self._sessions[session_id]
            return True
        return False

    def list_sessions(self) -> list[dict]:
        """List all active sessions."""
        return [
            session.get_state()
            for session in self._sessions.values()
        ]

    def cleanup_ended_sessions(self) -> int:
        """Remove ended sessions. Returns count of removed sessions."""
        ended = [
            sid for sid, session in self._sessions.items()
            if session.state == SessionState.ENDED
        ]
        for sid in ended:
            del self._sessions[sid]
        return len(ended)
