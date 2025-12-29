# UMCF Standards Traceability Matrix

This document provides field-by-field traceability from UMCF to established educational standards.

## Standards Referenced

| Abbreviation | Full Name | Specification |
|--------------|-----------|---------------|
| **LOM** | IEEE Learning Object Metadata | [IEEE 1484.12.1-2020](https://standards.ieee.org/standard/1484_12_1-2020.html) |
| **LRMI** | Learning Resource Metadata Initiative | [LRMI (Dublin Core)](https://www.dublincore.org/specifications/lrmi/) |
| **DC** | Dublin Core Metadata | [DCMI Terms](https://www.dublincore.org/specifications/dublin-core/dcmi-terms/) |
| **SCORM** | Sharable Content Object Reference Model | [SCORM 2004](https://scorm.com/scorm-explained/) |
| **xAPI** | Experience API | [xAPI Specification](https://xapi.com/overview/) |
| **CASE** | Competency and Academic Standards Exchange | [CASE 1.0](https://www.imsglobal.org/spec/case/v1p0) |
| **QTI** | Question and Test Interoperability | [QTI 3.0](https://www.imsglobal.org/spec/qti/v3p0) |
| **OB** | Open Badges | [Open Badges 3.0](https://www.imsglobal.org/spec/ob/v3p0) |
| **CC** | Creative Commons | [CC Licenses](https://creativecommons.org/licenses/) |
| **ISO 8601** | Date/Time Format | [ISO 8601](https://www.iso.org/iso-8601-date-and-time-format.html) |
| **BCP 47** | Language Tags | [BCP 47](https://www.rfc-editor.org/info/bcp47) |
| **UMCF** | Una Mentis Curriculum Format | Native (this specification) |

---

## Top-Level Fields

| UMCF Field | Source Standard | Standard Path | Notes |
|------------|-----------------|---------------|-------|
| `umcf` | JSON Schema | `$schema` convention | Version identifier |
| `id` | LOM, DC | LOM General.Identifier, dc:identifier | Combined |
| `id.catalog` | LOM | General.Identifier.Catalog | Namespace |
| `id.value` | LOM | General.Identifier.Entry | Actual value |
| `title` | LOM, LRMI, DC | LOM General.Title, schema:name, dc:title | All equivalent |
| `description` | LOM, LRMI, DC | LOM General.Description, schema:description, dc:description | All equivalent |
| `version` | LOM | LifeCycle.Version | Extended with semver |
| `version.number` | SemVer | Semantic Versioning 2.0 | Pattern enforced |
| `version.date` | LOM | LifeCycle.Contribute.Date | ISO 8601 |
| `version.changelog` | UMCF | Native | Software convention |

---

## Lifecycle

| UMCF Field | Source Standard | Standard Path | Notes |
|------------|-----------------|---------------|-------|
| `lifecycle.status` | LOM | LifeCycle.Status | Vocabulary: draft, final, revised, unavailable |
| `lifecycle.contributors` | LOM, DC | LifeCycle.Contribute, dc:contributor | Array of contributors |
| `lifecycle.created` | DC | dc:created | ISO 8601 datetime |
| `lifecycle.modified` | DC | dc:modified | ISO 8601 datetime |
| `lifecycle.validFrom` | OB | Assertion.issuedOn | Content validity start |
| `lifecycle.validUntil` | OB | Assertion.expires | Expiration date |

### Contributor

| UMCF Field | Source Standard | Standard Path | Notes |
|------------|-----------------|---------------|-------|
| `contributor.id` | vCard, ORCID | vCard UID | Optional identifier |
| `contributor.name` | LOM | Contribute.Entity (vCard FN) | Display name |
| `contributor.role` | LOM | Contribute.Role | LOM vocabulary |
| `contributor.organization` | vCard | ORG | Affiliation |
| `contributor.email` | vCard | EMAIL | Contact |
| `contributor.date` | LOM | Contribute.Date | Contribution date |

---

## Metadata

| UMCF Field | Source Standard | Standard Path | Notes |
|------------|-----------------|---------------|-------|
| `metadata.language` | LOM, DC | General.Language, dc:language | BCP 47 format |
| `metadata.keywords` | LOM, DC | General.Keyword, dc:subject | Array of strings |
| `metadata.coverage` | LOM, DC | General.Coverage, dc:coverage | Topical/temporal |
| `metadata.structure` | LOM | General.Structure | Vocabulary enforced |
| `metadata.aggregationLevel` | LOM | General.AggregationLevel | 1-4 scale |

---

## Educational Context

| UMCF Field | Source Standard | Standard Path | Notes |
|------------|-----------------|---------------|-------|
| `educational.interactivityType` | LOM | Educational.InteractivityType | active/expositive/mixed |
| `educational.interactivityLevel` | LOM | Educational.InteractivityLevel | 5-level scale |
| `educational.learningResourceType` | LOM, LRMI | Educational.LearningResourceType, schema:learningResourceType | Array, LOM vocabulary |
| `educational.intendedEndUserRole` | LOM | Educational.IntendedEndUserRole | teacher/author/learner/manager |
| `educational.context` | LOM | Educational.Context | school/higher education/training/other |
| `educational.typicalAgeRange` | LOM, LRMI | Educational.TypicalAgeRange, schema:typicalAgeRange | String range |
| `educational.difficulty` | LOM | Educational.Difficulty | 5-level scale |
| `educational.typicalLearningTime` | LOM | Educational.TypicalLearningTime | ISO 8601 duration |
| `educational.educationalAlignment` | LRMI, CASE | schema:educationalAlignment | Array of alignments |

### Educational Alignment

| UMCF Field | Source Standard | Standard Path | Notes |
|------------|-----------------|---------------|-------|
| `educationalAlignment.alignmentType` | LRMI | AlignmentObject.alignmentType | Vocabulary from LRMI |
| `educationalAlignment.educationalFramework` | LRMI, CASE | AlignmentObject.educationalFramework, CFDocument.title | Framework name |
| `educationalAlignment.targetName` | LRMI, CASE | AlignmentObject.targetName, CFItem.fullStatement | Standard name |
| `educationalAlignment.targetUrl` | LRMI, CASE | AlignmentObject.targetUrl, CFItem.uri | Standard URL |
| `educationalAlignment.targetDescription` | LRMI | AlignmentObject.targetDescription | Description |

### Audience Profile

| UMCF Field | Source Standard | Standard Path | Notes |
|------------|-----------------|---------------|-------|
| `audienceProfile.educationLevel` | LRMI | schema:educationalLevel | ISCED-inspired |
| `audienceProfile.gradeLevel` | LRMI | schema:typicalGradeLevel | US grade system |
| `audienceProfile.prerequisites` | LRMI | schema:coursePrerequisites | Array |
| `audienceProfile.roleRequirements` | OB, Corporate | Corporate training practice | Job roles |

---

## Rights

| UMCF Field | Source Standard | Standard Path | Notes |
|------------|-----------------|---------------|-------|
| `rights.cost` | LOM | Rights.Cost | Boolean |
| `rights.copyrightAndOtherRestrictions` | LOM | Rights.CopyrightAndOtherRestrictions | Boolean |
| `rights.description` | LOM | Rights.Description | Free text |
| `rights.license.type` | CC, SPDX | Creative Commons identifiers | e.g., CC-BY-4.0 |
| `rights.license.url` | CC | License URL | Link to license |
| `rights.attributionRequirements` | CC | Attribution clause | Required text |
| `rights.holder` | DC | dc:rightsHolder | Rights owner |

---

## Compliance Requirements

| UMCF Field | Source Standard | Standard Path | Notes |
|------------|-----------------|---------------|-------|
| `compliance.certification` | OB | BadgeClass | Badge/certificate config |
| `compliance.regulatoryFrameworks` | Corporate | Industry standards | SOC2, HIPAA, etc. |
| `compliance.renewalPolicy` | Corporate | Training practice | Recertification |
| `compliance.auditRequirements` | xAPI, Corporate | Statement logging | Audit trail config |

### Certification

| UMCF Field | Source Standard | Standard Path | Notes |
|------------|-----------------|---------------|-------|
| `certification.id` | OB | BadgeClass.id | Badge identifier |
| `certification.name` | OB | BadgeClass.name | Display name |
| `certification.description` | OB | BadgeClass.description | What it represents |
| `certification.image` | OB | BadgeClass.image | Badge image URL |
| `certification.criteria` | OB | BadgeClass.criteria | Earning criteria |
| `certification.criteria.narrative` | OB | Criteria.narrative | Text description |
| `certification.issuer` | OB | Issuer | Issuing organization |
| `certification.validityPeriod` | OB, Corporate | Expiration practice | ISO 8601 duration |
| `certification.alignment` | OB | BadgeClass.alignment | Standard alignment |

### Audit Requirements

| UMCF Field | Source Standard | Standard Path | Notes |
|------------|-----------------|---------------|-------|
| `auditRequirements.enabled` | Corporate | Compliance practice | Toggle |
| `auditRequirements.retentionPeriod` | Corporate | Legal requirements | ISO 8601 duration |
| `auditRequirements.requiredEvents` | xAPI | Verb vocabulary | started, completed, etc. |
| `auditRequirements.dataFields` | xAPI | Statement components | What to capture |
| `auditRequirements.signatureRequired` | Corporate | Compliance practice | Digital signature |
| `auditRequirements.supervisorApproval` | Corporate | HR/training practice | Sign-off required |

---

## Content Node

| UMCF Field | Source Standard | Standard Path | Notes |
|------------|-----------------|---------------|-------|
| `contentNode.id` | SCORM, LOM | item.identifier, General.Identifier | Required |
| `contentNode.title` | SCORM, LOM | item.title, General.Title | Required |
| `contentNode.type` | UMCF | Native | Tutoring-specific types |
| `contentNode.orderIndex` | SCORM | Sequencing order | Sequence position |
| `contentNode.description` | LOM | General.Description | Optional |
| `contentNode.learningObjectives` | CASE, LRMI | CFItem, schema:teaches | Array |
| `contentNode.prerequisites` | SCORM | Sequencing.prerequisites | Dependencies |
| `contentNode.timeEstimates` | LOM | Educational.TypicalLearningTime | By depth level |
| `contentNode.transcript` | UMCF | Native | Tutoring dialogue |
| `contentNode.examples` | UMCF | Native | Instructional examples |
| `contentNode.assessments` | QTI | assessmentItem | Questions/quizzes |
| `contentNode.glossaryTerms` | UMCF | Native | Node-specific terms |
| `contentNode.misconceptions` | UMCF | Native | Error handling |
| `contentNode.resources` | LOM, SCORM | Relation, resource | External refs |
| `contentNode.children` | UMCF | Native (recursive) | Nested nodes |
| `contentNode.tutoringConfig` | UMCF | Native | AI settings |
| `contentNode.compliance` | Corporate | Training practice | Node requirements |
| `contentNode.extensions` | xAPI | extensions pattern | Custom data |

---

## Learning Objective

| UMCF Field | Source Standard | Standard Path | Notes |
|------------|-----------------|---------------|-------|
| `learningObjective.id` | CASE | CFItem.identifier | Unique ID |
| `learningObjective.statement` | CASE | CFItem.fullStatement | Full text |
| `learningObjective.abbreviatedStatement` | CASE | CFItem.abbreviatedStatement | Short form |
| `learningObjective.bloomsLevel` | Bloom's Taxonomy | Cognitive domain | 6 levels |
| `learningObjective.educationalAlignment` | LRMI, CASE | educationalAlignment, CFAssociation | Standards link |
| `learningObjective.verificationCriteria` | UMCF | Native | How to verify |
| `learningObjective.assessmentIds` | QTI | outcomeDeclaration | Linked assessments |

---

## Transcript (UMCF Native)

These elements are native to UMCF, designed for conversational AI tutoring.

| UMCF Field | Source Standard | Inspiration/Rationale |
|------------|-----------------|----------------------|
| `transcript.segments` | UMCF | Structured dialogue units |
| `transcript.totalDuration` | ISO 8601 | Standard duration format |
| `transcript.voiceProfile` | UMCF | TTS optimization |
| `transcriptSegment.id` | UMCF | Unique segment reference |
| `transcriptSegment.type` | UMCF | Pedagogical segment types |
| `transcriptSegment.content` | UMCF | Spoken text |
| `transcriptSegment.speakingNotes` | UMCF | TTS delivery hints |
| `transcriptSegment.checkpoint` | UMCF, QTI | Interactive verification (QTI-inspired) |
| `transcriptSegment.stoppingPoint` | UMCF | Natural pause configuration |
| `transcriptSegment.alternativeExplanations` | UMCF | Rephrasing support |
| `transcriptSegment.estimatedDuration` | ISO 8601 | Standard duration format |

### Checkpoint (UMCF Native, QTI-Inspired)

| UMCF Field | Inspiration | Notes |
|------------|-------------|-------|
| `checkpoint.type` | UMCF | Verification level |
| `checkpoint.prompt` | QTI | Question text |
| `checkpoint.expectedResponsePatterns` | QTI responseDeclaration | Pattern matching |
| `checkpoint.transitions` | UMCF | Branching logic |
| `checkpoint.fallbackBehavior` | UMCF | Error handling |

### Speaking Notes (UMCF Native)

| UMCF Field | Inspiration | Notes |
|------------|-------------|-------|
| `speakingNotes.pace` | TTS practice | Speech rate |
| `speakingNotes.emphasis` | SSML | Word emphasis |
| `speakingNotes.pauseAfter` | SSML | Insert pause |
| `speakingNotes.pauseDuration` | SSML | Pause length |
| `speakingNotes.emotionalTone` | TTS practice | Voice affect |

---

## Misconception (UMCF Native)

| UMCF Field | Inspiration | Notes |
|------------|-------------|-------|
| `misconception.id` | UMCF | Unique identifier |
| `misconception.misconception` | Pedagogical research | The error |
| `misconception.triggerPhrases` | UMCF | Detection patterns |
| `misconception.correction` | Pedagogical research | Correct understanding |
| `misconception.spokenCorrection` | UMCF | TTS-optimized |
| `misconception.explanation` | Pedagogical research | Why it happens |
| `misconception.remediationPath` | UMCF | Recovery guidance |
| `misconception.severity` | UMCF | Impact level |

---

## Example (UMCF Native)

| UMCF Field | Inspiration | Notes |
|------------|-------------|-------|
| `example.id` | UMCF | Unique identifier |
| `example.type` | Educational practice | code, scenario, analogy, etc. |
| `example.title` | UMCF | Display title |
| `example.content` | UMCF | Example content |
| `example.spokenContent` | UMCF | TTS-optimized |
| `example.complexity` | UMCF | Difficulty indicator |
| `example.codeLanguage` | UMCF | Programming language |
| `example.codeExplanation` | UMCF | Line-by-line for voice |
| `example.walkthrough` | UMCF | Step-by-step guide |

---

## Assessment (QTI-Aligned)

| UMCF Field | Source Standard | Standard Path | Notes |
|------------|-----------------|---------------|-------|
| `assessment.id` | QTI | assessmentItem.identifier | Required |
| `assessment.type` | QTI | interaction types | Basic set only |
| `assessment.title` | QTI | assessmentItem.title | Display title |
| `assessment.prompt` | QTI | prompt/itemBody | Question stem |
| `assessment.spokenPrompt` | UMCF | Native | TTS-optimized |
| `assessment.choices` | QTI | simpleChoice | Answer options |
| `assessment.choices[].id` | QTI | simpleChoice.identifier | Choice ID |
| `assessment.choices[].text` | QTI | simpleChoice content | Display text |
| `assessment.choices[].correct` | QTI | correctResponse | Is correct? |
| `assessment.choices[].feedback` | QTI | modalFeedback | Choice feedback |
| `assessment.correctResponse` | QTI | responseDeclaration.correctResponse | Correct answer(s) |
| `assessment.scoring` | QTI | outcomeDeclaration | Score config |
| `assessment.scoring.maxScore` | QTI | normalMaximum | Maximum points |
| `assessment.scoring.passingScore` | QTI | Custom | Pass threshold |
| `assessment.feedback` | QTI | modalFeedback | Feedback config |
| `assessment.hints` | QTI | feedbackBlock | Progressive hints |
| `assessment.difficulty` | IRT | Item difficulty | 0-1 scale |
| `assessment.objectivesAssessed` | QTI | outcomeDeclaration | Linked objectives |
| `assessment.attempts` | QTI | itemSessionControl.maxAttempts | Attempt limit |

---

## Glossary

| UMCF Field | Source Standard | Standard Path | Notes |
|------------|-----------------|---------------|-------|
| `glossary.terms` | UMCF | Native | Term array |
| `glossaryTerm.id` | UMCF | Native | Unique ID |
| `glossaryTerm.term` | UMCF | Native | The word/phrase |
| `glossaryTerm.pronunciation` | UMCF | Native (IPA) | For TTS |
| `glossaryTerm.definition` | UMCF | Native | Definition text |
| `glossaryTerm.spokenDefinition` | UMCF | Native | TTS-optimized |
| `glossaryTerm.simpleDefinition` | UMCF | Native | For younger audiences |
| `glossaryTerm.synonyms` | UMCF | Native | Alternative terms |
| `glossaryTerm.relatedTerms` | UMCF | Native | Related concepts |
| `glossaryTerm.etymology` | UMCF | Native | Word origin |

---

## Resource (LOM-Aligned)

| UMCF Field | Source Standard | Standard Path | Notes |
|------------|-----------------|---------------|-------|
| `resource.type` | LOM | Relation.Kind | Relationship type |
| `resource.identifier` | LOM | Relation.Resource.Identifier | Resource ID |
| `resource.url` | LOM | Relation.Resource (via Identifier) | Resource URL |
| `resource.title` | LOM | Relation.Resource.Description | Display title |
| `resource.description` | LOM | Relation.Resource.Description | Description |
| `resource.format` | LOM | Technical.Format | MIME type |

---

## Tutoring Config (UMCF Native)

| UMCF Field | Inspiration | Notes |
|------------|-------------|-------|
| `tutoringConfig.contentDepth` | UnaMentis ContentDepth | Depth level enum |
| `tutoringConfig.adaptiveDepth` | UMCF | Allow dynamic adjustment |
| `tutoringConfig.systemPromptOverride` | UMCF | Custom AI instructions |
| `tutoringConfig.interactionMode` | UMCF | lecture/socratic/practice/etc. |
| `tutoringConfig.allowTangents` | UMCF | Off-topic exploration |
| `tutoringConfig.escalationThreshold` | UMCF | When to use frontier LLM |
| `tutoringConfig.checkpointFrequency` | UMCF | Verification frequency |

---

## Node Compliance (UMCF Native + Corporate)

| UMCF Field | Inspiration | Notes |
|------------|-------------|-------|
| `nodeCompliance.mandatory` | Corporate training | Required for certification |
| `nodeCompliance.passingCriteria` | Corporate training | Pass requirements |
| `nodeCompliance.passingCriteria.minimumScore` | QTI, Corporate | Score threshold |
| `nodeCompliance.passingCriteria.minimumTime` | Corporate | Time requirement |
| `nodeCompliance.trackingLevel` | xAPI, Corporate | Detail level |

---

## Extensions (xAPI Pattern)

| UMCF Field | Source Standard | Standard Path | Notes |
|------------|-----------------|---------------|-------|
| `extensions` | xAPI | extensions pattern | Namespaced custom data |

Extensions use URI-based namespaces following the xAPI convention:

```json
{
  "https://example.com/extensions/custom": {
    "customField": "value"
  }
}
```

---

## Duration Formats (ISO 8601)

All duration fields use ISO 8601 duration format:

| Format | Meaning | Example |
|--------|---------|---------|
| `PTnM` | n minutes | `PT30M` = 30 minutes |
| `PTnH` | n hours | `PT2H` = 2 hours |
| `PTnHnM` | hours and minutes | `PT1H30M` = 90 minutes |
| `PnD` | n days | `P1D` = 1 day |
| `PnM` | n months | `P6M` = 6 months |
| `PnY` | n years | `P1Y` = 1 year |

---

## Summary Statistics

| Category | Total Fields | From Standards | UMCF Native |
|----------|--------------|----------------|-------------|
| Top-Level | 12 | 11 | 1 |
| Lifecycle | 8 | 8 | 0 |
| Metadata | 5 | 5 | 0 |
| Educational | 14 | 13 | 1 |
| Rights | 7 | 7 | 0 |
| Compliance | 20 | 10 | 10 |
| Content Node | 17 | 8 | 9 |
| Learning Objective | 7 | 5 | 2 |
| Transcript | 18 | 2 | 16 |
| Assessment | 15 | 13 | 2 |
| Glossary | 10 | 0 | 10 |
| Misconception | 9 | 0 | 9 |
| Example | 10 | 0 | 10 |
| **TOTAL** | **152** | **82 (54%)** | **70 (46%)** |

This balance reflects UMCF's design goal: leverage established standards for interoperability while adding native support for conversational AI tutoring features not covered by existing specifications.
