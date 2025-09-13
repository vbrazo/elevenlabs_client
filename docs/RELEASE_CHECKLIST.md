# Release Checklist

This document outlines the steps for releasing a new version of the ElevenlabsClient gem.

## Pre-Release Checklist

### ✅ Code Quality
- [x] All tests passing (187 examples, 0 failures)
- [x] Code coverage is comprehensive
- [x] No linting errors or warnings
- [x] Documentation is up to date

### ✅ Version Management
- [x] Version number updated in `lib/elevenlabs_client/version.rb`
- [x] CHANGELOG.md updated with new features and changes
- [x] Breaking changes documented with migration guide
- [x] All new features documented

### ✅ Documentation
- [x] README.md streamlined and improved
- [x] Endpoint documentation moved to separate files in `docs/`
- [x] All examples updated and tested
- [x] Rails integration examples provided

### ✅ File Management
- [x] .gitignore updated with comprehensive entries
- [x] Unnecessary files removed or ignored
- [x] Gem builds successfully without warnings

## Release Steps

### 1. Final Testing
```bash
# Run all tests
bundle exec rspec

# Build gem
gem build elevenlabs_client.gemspec

# Test gem installation locally
gem install ./elevenlabs_client-0.2.0.gem
```

### 2. Git Management
```bash
# Commit all changes
git add .
git commit -m "Release v0.2.0: Add TTS, Streaming, Dialogue, and Sound Generation APIs"

# Tag the release
git tag v0.2.0

# Push to repository
git push origin main
git push origin v0.2.0
```

### 3. Gem Publication
```bash
# Publish to RubyGems (when ready)
gem push elevenlabs_client-0.2.0.gem
```

## Post-Release

### Documentation Updates
- [ ] Update GitHub repository description
- [ ] Create GitHub release with changelog
- [ ] Update any external documentation links
- [ ] Announce release in relevant communities

### Monitoring
- [ ] Monitor for any issues or bug reports
- [ ] Check gem download statistics
- [ ] Respond to user feedback and questions

## Version 0.2.0 Summary

### Major Features Added
- **Text-to-Speech API** - Convert text to natural speech
- **Text-to-Speech Streaming** - Real-time audio streaming
- **Text-to-Dialogue API** - Multi-speaker conversations
- **Sound Generation API** - AI-generated sound effects
- **Enhanced Architecture** - Modular endpoint organization
- **Comprehensive Documentation** - Separate docs for each API

### Statistics
- **Test Coverage**: 187 tests, 0 failures
- **New Endpoints**: 4 major API endpoints added
- **Documentation**: 5 detailed API documentation files
- **Examples**: 6 complete Rails controller examples
- **Breaking Changes**: Endpoint access pattern (with migration guide)

### Files Changed
- `README.md` - Completely restructured and improved
- `CHANGELOG.md` - Comprehensive release notes
- `lib/elevenlabs_client/version.rb` - Version bump to 0.2.0
- `.gitignore` - Enhanced with comprehensive entries
- `docs/` - New directory with 5 API documentation files
- `lib/elevenlabs_client/endpoints/` - All endpoint classes
- `examples/` - 6 complete Rails integration examples

This release represents a major expansion of the gem's capabilities, transforming it from a dubbing-only client to a comprehensive ElevenLabs API wrapper.
