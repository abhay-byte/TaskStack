# Todo Tasks

All core offline features have been implemented. See `finished-tasks.md` for details.

## ☁️ Phase 6: Backend API Implementation (Node.js + Postgres)
- [ ] Write `backend/routes/groups.js` (CRUD groups, members)
- [ ] Write `backend/routes/invites.js` (Create, accept, reject invites)
- [ ] Setup `qr-code` generation endpoint for group invites
- [ ] Create `server.js` and finalise API setup
- [ ] Test API endpoints with mock requests

## 📱 Phase 7: Flutter Cloud Integration — Auth
- [ ] Add `dio` and `flutter_secure_storage` dependencies
- [ ] Create `AuthRepository` and StateNotifier for auth state
- [ ] Build `LoginScreen` and `SignupScreen`
- [ ] Implement GoRouter guard for auth requirement

## 📱 Phase 8: Flutter Cloud Integration — Social & Groups
- [ ] Create `GroupRepository` and StateNotifier
- [ ] Build `GroupsListScreen`, `CreateGroupScreen`, and `GroupDetailScreen`
- [ ] Build `InviteScreen` (QR code display) and `JoinGroupScreen` (QR scanner)
- [ ] Handle invite accept/reject actions

## 📱 Phase 9: Flutter Cloud Integration — Profiles
- [ ] Build `MyProfileScreen` to edit bio/avatar and toggle public status
- [ ] Build `UserProfileScreen` to view other users (restricted by group/public status)

## 🔄 Future Enhancements (Post v1.0)
- Signed release APK (requires a keystore — set up manually)
- Flavour productFlavours in build.gradle.kts (see `docs/flavour-config.md`)
- Persist notifications across restarts with a headless background Dart isolate (advanced)
- Deeper analytics: streak tracking, category time breakdowns
- Search across tasks (full-text)
- Widget (home screen widget) for today's top 3 tasks
