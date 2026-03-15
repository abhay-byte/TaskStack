# OpenViking AI Agent Integration Guide

## Overview
This project uses **OpenViking**, an Agent-native context database, to manage all project documentation, architecture, and context. 

Instead of reading raw files, **all AI Agents assisting on this project MUST retrieve project details exclusively from the OpenViking Server.**

## Mandatory AI Agent Instructions
If you are an AI assistant or an Agent working on the TaskStack project, you must follow these rules:

1. **Verify Server Status**: Before answering architecture or project-specific questions, check if OpenViking is running.
2. **Start Server (If Offline)**: If the server is not running, you must start it in the background before proceeding.
3. **Fetch Context via CLI**: Always use the OpenViking CLI (`ov`) to fetch contexts instead of directly reading files like `api.md` or `srs.md` if the information is meant to be retrieved semantically.

## Quick Start for Agents

### 1. Check if OpenViking is Running
Run the following health check:
```bash
curl http://localhost:1933/health
```
If it returns `{"status": "ok"}`, the server is running. Proceed to step 3.

### 2. Start the Server
If the server is offline, start it in the background:
```bash
nohup openviking-server --with-bot > ~/.openviking/server.log 2>&1 &
```
Wait a few seconds and run the health check again.

### 3. Fetching Details
All TaskStack project documentation is stored under the URI `viking://resources/docs`.

To search for a specific topic, use the `find` command. 
For example, to understand how "Group Invites" work:
```bash
ov find "How do group invites work in TaskStack?" --uri viking://resources/docs
```

To list all available documents:
```bash
ov ls viking://resources/docs
```

To read the structural overview of a directory:
```bash
ov overview viking://resources/docs/api
```

## Important Notes
- **Do NOT** bypass OpenViking for project understanding. It contains the most up-to-date semantic graphs and structural summaries of the project state.
- If you create new documentation or modify existing ones significantly, you MUST re-index it into OpenViking:
  ```bash
  ov rm viking://resources/docs -r
  ov add-resource ./docs/ --wait
  ```
