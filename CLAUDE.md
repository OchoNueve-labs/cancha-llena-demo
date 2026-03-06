# N8N to App Builder

Convert n8n workflows into production-ready Next.js web applications.

## Project Goal

Transform n8n workflows into standalone web apps with proper front-ends, deployed automatically via GitHub → Vercel.

## Workflow

### Phase 1: n8n Workflow Optimization
- Review existing n8n workflow structure
- Ensure proper webhook intake configuration (POST/GET endpoints)
- Validate data input/output schema
- Test response format for front-end consumption
- Document expected payload structure

### Phase 2: Front-End Development
- Build Next.js + React app locally
- Create forms/UI matching workflow inputs
- Implement API routes to call n8n webhooks
- Handle responses and display results
- Test end-to-end locally

### Phase 3: Deployment Pipeline
- Push to GitHub repository
- Connect to Vercel for auto-deployment
- Configure environment variables (webhook URLs)
- Test production deployment

## Tech Stack

- **Framework**: Next.js 14+ (App Router)
- **UI Library**: React 18+
- **Styling**: Tailwind CSS
- **Deployment**: Vercel
- **Version Control**: GitHub
- **Backend**: n8n workflows (webhook endpoints)

## Project Structure

```
/
├── app/                    # Next.js app directory
│   ├── api/               # API routes (proxy to n8n)
│   ├── components/        # React components
│   └── page.tsx           # Main app page
├── public/                # Static assets
├── .env.local            # Local environment variables
├── .env.example          # Environment template
├── next.config.js        # Next.js configuration
├── tailwind.config.js    # Tailwind configuration
├── package.json          # Dependencies
└── README.md             # App-specific documentation
```

## Environment Variables

Required for each environment (dev/staging/prod):

```env
# n8n Webhook URLs
NEXT_PUBLIC_N8N_WEBHOOK_URL=https://your-n8n-instance.com/webhook/...
N8N_WEBHOOK_SECRET=optional-secret-token

# App Configuration
NEXT_PUBLIC_APP_NAME=Your App Name
NEXT_PUBLIC_APP_URL=https://your-app.vercel.app
```

## MCP Tools Available

- **n8n MCP**: View/modify workflows, nodes, configurations, templates
- **GitHub MCP**: Push changes, manage repositories
- **Front-end Designer Skill**: UI/UX optimization
- **n8n Skill**: Workflow-specific operations

## Development Workflow

1. **Start new app**: Create repo from this template structure
2. **Configure n8n**: Optimize workflow for app integration
3. **Build locally**: `npm run dev` and iterate
4. **Test integration**: Verify n8n ↔ front-end communication
5. **Deploy**: Push to GitHub → auto-deploys to Vercel
6. **Iterate**: Changes to GitHub automatically update Vercel

## Key Principles

- **Keep it simple**: One app per n8n workflow
- **Environment separation**: Different webhook URLs for dev/prod
- **n8n handles logic**: Front-end is UI layer only
- **Auto-deployment**: GitHub push = Vercel update
- **Clean structure**: Organized, minimal, maintainable

## Before Starting Each App

1. Identify which n8n workflow to convert
2. Document the workflow's input/output schema
3. Verify webhook endpoint is production-ready
4. Choose app name and create GitHub repo
5. Set up Vercel project linked to repo

## Common Patterns

### n8n Webhook Setup
- Use Production webhook URLs (not test URLs)
- Return JSON responses with consistent structure
- Include error handling in workflow
- Set appropriate HTTP status codes

### Front-End API Pattern
```typescript
// app/api/workflow/route.ts
export async function POST(request: Request) {
  const data = await request.json();
  const response = await fetch(process.env.NEXT_PUBLIC_N8N_WEBHOOK_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data),
  });
  return response;
}
```

### Form → API → n8n → Display
1. User fills form in React component
2. Submit calls `/api/workflow`
3. API route proxies to n8n webhook
4. n8n processes and returns response
5. Display results to user

## Success Criteria

✅ n8n workflow accepts and returns data correctly
✅ Front-end successfully communicates with n8n
✅ App deployed on Vercel with proper env vars
✅ GitHub → Vercel auto-deployment working
✅ Clean, maintainable code structure

---

**Last Updated**: 2026-01-16
