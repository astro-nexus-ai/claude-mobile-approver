# Screenshots & Demo Images

This directory contains screenshots and demo images for documentation.

## Required Images

Please add the following images to improve the README:

### 1. `demo.gif` (Recommended)
A 10-15 second GIF showing the complete flow:
1. Claude Code requests permission
2. Phone receives notification
3. User taps notification
4. Approval page opens
5. User taps Approve
6. Claude Code continues

**Tips for recording**:
- Use clean, minimal terminal theme
- Use iOS/Android screen recording
- Convert to GIF using: `ffmpeg -i demo.mp4 -vf "fps=10,scale=320:-1" demo.gif`
- Keep file size under 2MB

### 2. `notification-ios.png`
Screenshot of push notification on iOS lock screen.

### 3. `notification-android.png`
Screenshot of push notification on Android.

### 4. `approval-page.png`
Screenshot of the approval web page showing:
- Tool name
- Command/file details
- Approve/Deny buttons

### 5. `architecture.png` (Optional)
Export from ARCHITECTURE.md Mermaid diagram.

## Image Guidelines

- **Format**: PNG for screenshots, GIF for demos
- **Size**: Max 800px width for README
- **Privacy**: Blur or remove any sensitive information (IPs, passwords, real names)

## How to Add

1. Add images to this directory
2. Reference in README.md:
   ```markdown
   ![Demo](docs/images/demo.gif)
   ```
