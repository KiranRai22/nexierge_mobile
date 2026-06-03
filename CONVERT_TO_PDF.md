# How to Convert Documentation to PDF

## Method 1: VS Code Extension (Easiest)
1. Install **"Markdown PDF"** extension by yzane
2. Open `TECHNICAL_DOCUMENTATION.md` in VS Code
3. Right-click → "Markdown PDF: Export (pdf)"
4. PDF will be generated in the same folder

## Method 2: Using Node.js (If Available)
```bash
cd /Users/kiranrai/Desktop/Development/Flutter/nexierge/scripts
npm install
npm run convert
```

## Method 3: Using Pandoc (If LaTeX Installed)
```bash
cd /Users/kiranrai/Desktop/Development/Flutter/nexierge
pandoc TECHNICAL_DOCUMENTATION.md -o TECHNICAL_DOCUMENTATION.pdf
```

## Method 4: Online Converter
1. Go to https://www.markdowntopdf.com/ or https://md2pdf.netlify.app/
2. Upload `TECHNICAL_DOCUMENTATION.md`
3. Download the generated PDF

## Method 5: Using Chrome/Edge Browser
1. Open the markdown file in VS Code
2. Preview with "Markdown Preview Enhanced" extension
3. Right-click in preview → "Open in Browser"
4. Print to PDF (Ctrl+P / Cmd+P → Save as PDF)

---

## Documentation Summary

The technical documentation has been created at:
**`/Users/kiranrai/Desktop/Development/Flutter/nexierge/TECHNICAL_DOCUMENTATION.md`**

### Contents Include:
1. **Project Overview** - Technology stack and key features
2. **Architecture Overview** - Clean Architecture + MVVM diagrams
3. **Project Structure** - Directory organization
4. **State Management** - Riverpod patterns and provider types
5. **Data Layer** - Repository pattern and data flow
6. **Feature Modules** - Dashboard, Tickets, Auth, Notifications
7. **Real-time Communication** - Socket.IO architecture
8. **Authentication & Security** - JWT flow and secure storage
9. **Push Notifications** - FCM setup and configuration
10. **Internationalization** - ARB structure and usage
11. **Testing Strategy** - Unit and widget testing patterns
12. **Development Guidelines** - Naming conventions and best practices

### File Locations:
- Main Doc: `TECHNICAL_DOCUMENTATION.md`
- Conversion Scripts: `scripts/` folder
- Styling: `scripts/pdf-style.css`
