#!/usr/bin/env python3
"""
Update UnaMentis Xcode project to replace Stanford BDHG llama.cpp SPM package
with the local llama.xcframework.

This script:
1. Removes the Stanford BDHG llama.cpp SPM package reference
2. Adds the local llama.xcframework as a framework reference
3. Updates the Frameworks build phase to use the XCFramework

Run from project root: python scripts/update_llama_xcframework.py
"""

import os
import re
import uuid

def generate_uuid():
    """Generate a 24-character uppercase hex UUID for Xcode."""
    return uuid.uuid4().hex[:24].upper()

def main():
    # Get the project root (parent of scripts directory)
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(script_dir)
    project_path = os.path.join(project_root, "UnaMentis.xcodeproj", "project.pbxproj")

    with open(project_path, 'r') as f:
        content = f.read()

    # New UUIDs for the XCFramework entries
    xcframework_file_ref = "LLAMA_XCFW_FILE_REF01"  # File reference
    xcframework_build_file = "LLAMA_XCFW_BUILD_001"  # Build file

    # 1. Remove SPM package reference from packageReferences array
    # Find and remove: DFE4B4FF31760BA3EED2AA3B /* XCRemoteSwiftPackageReference "llama.cpp" */,
    content = re.sub(
        r'\s*DFE4B4FF31760BA3EED2AA3B /\* XCRemoteSwiftPackageReference "llama\.cpp" \*/,?\n?',
        '',
        content
    )

    # 2. Remove SPM product dependency from packageProductDependencies array
    # Find and remove: 2FC2771025B94B26F3E99434 /* llama */,
    content = re.sub(
        r'\s*2FC2771025B94B26F3E99434 /\* llama \*/,?\n?',
        '',
        content
    )

    # 3. Remove the XCRemoteSwiftPackageReference section for llama.cpp
    # Remove the entire block from DFE4B4FF31760BA3EED2AA3B to the closing };
    content = re.sub(
        r'\s*DFE4B4FF31760BA3EED2AA3B /\* XCRemoteSwiftPackageReference "llama\.cpp" \*/ = \{[^}]+\};',
        '',
        content
    )

    # 4. Remove the XCSwiftPackageProductDependency section for llama
    content = re.sub(
        r'\s*2FC2771025B94B26F3E99434 /\* llama \*/ = \{[^}]+\};',
        '',
        content
    )

    # 5. Replace the old build file entry for llama in Frameworks
    # Change A956730A34A900A2D80350F7 /* llama in Frameworks */ to use the XCFramework
    content = re.sub(
        r'A956730A34A900A2D80350F7 /\* llama in Frameworks \*/ = \{isa = PBXBuildFile; productRef = 2FC2771025B94B26F3E99434 /\* llama \*/; \};',
        f'{xcframework_build_file} /* llama.xcframework in Frameworks */ = {{isa = PBXBuildFile; fileRef = {xcframework_file_ref} /* llama.xcframework */; }};',
        content
    )

    # 6. Update the Frameworks build phase to reference new build file
    content = re.sub(
        r'A956730A34A900A2D80350F7 /\* llama in Frameworks \*/',
        f'{xcframework_build_file} /* llama.xcframework in Frameworks */',
        content
    )

    # 7. Add PBXFileReference for llama.xcframework
    # Find the end of PBXFileReference section and add before it
    file_ref_entry = f'''		{xcframework_file_ref} /* llama.xcframework */ = {{isa = PBXFileReference; lastKnownFileType = wrapper.xcframework; path = llama.xcframework; sourceTree = "<group>"; }};
'''

    # Insert after last PBXFileReference entry (before "/* End PBXFileReference section */")
    content = content.replace(
        '/* End PBXFileReference section */',
        file_ref_entry + '/* End PBXFileReference section */'
    )

    # 8. Add the XCFramework to the main group (447C0C055EDE0CF3C43929BC)
    # Find the main group and add the xcframework file reference to its children
    # Look for the mainGroup section and add to children

    # Find the group that contains UnaMentis folder and add xcframework there
    # Looking for group 447C0C055EDE0CF3C43929BC
    content = re.sub(
        r'(447C0C055EDE0CF3C43929BC /\* = group \*/ = \{\s*isa = PBXGroup;\s*children = \()',
        f'\\1\n\t\t\t\t{xcframework_file_ref} /* llama.xcframework */,',
        content
    )

    # If that didn't work, try a different pattern for the main group
    if xcframework_file_ref not in content.split('447C0C055EDE0CF3C43929BC')[1][:500] if '447C0C055EDE0CF3C43929BC' in content else True:
        # Try finding any group that has the frameworks and add it there
        pass

    with open(project_path, 'w') as f:
        f.write(content)

    print("Project file updated successfully!")
    print(f"- Removed Stanford BDHG llama.cpp SPM package reference")
    print(f"- Added llama.xcframework file reference: {xcframework_file_ref}")
    print(f"- Added llama.xcframework build file: {xcframework_build_file}")
    print("\nNote: You may need to open Xcode and manually add the XCFramework if it doesn't appear.")

if __name__ == "__main__":
    main()
