# Shared-35: Receipt Images - Attach Photos to Bills

## Purpose
Provide offline evidence storage for bills by allowing users to attach receipt photos when creating or editing a bill, compress photos for storage efficiency, display thumbnails on bill cards, and view high-resolution photos in an interactive gallery modal.

## Acceptance Criteria
1. Take photo or pick from gallery when creating/editing bill
2. Store image in app local cache (SQLite blob or file system)
3. Display thumbnail on bill card in list
4. Tap bill to view full-size receipt image in modal
5. Delete image option in bill edit screen
6. Support multiple images per bill (gallery view)
7. Image compression for storage efficiency
8. Persist across app restarts
9. Tests: 80+ covering image handling, persistence, gallery
