# CLAUDE.md - Project Configuration and Commands

## 📋 Project Overview
- **Project**: Moomoo DCA Custom Strategies
- **Current Version**: v2.2.5-Stable
- **Architecture**: Three-tier (Free/Paid/Premium)
- **Status**: Production ready, validation complete

## 🔧 Important Commands

### Git Operations
```bash
# Standard commit with Claude signature
git add . && git commit -m "$(cat <<'EOF'
[Commit message here]

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"

# Check status and diff in parallel
git status && git diff
```

### Validation and Testing
```bash
# Run comprehensive version validation
python3 tools/validate_both_versions.py

# Check Python syntax (no external dependencies)
python3 -m py_compile tools/validate_both_versions.py
```

### File Organization
```bash
# List strategy files
ls -la strategies/

# Check data reports
ls -la data/validation_reports/

# View project structure
tree -I '__pycache__|*.pyc|node_modules'
```

## 🏗️ Project Architecture

### File Structure
```
moomoo_custom_strategies/
├── strategies/
│   ├── dca_free_public.quant      # Free version (open source)
│   ├── dca_premium_moomoo.quant   # Paid version (protected)
│   └── dca_dev_mixed.quant        # Development version (gitignored)
├── tools/
│   └── validate_both_versions.py  # Validation framework
├── docs/
│   ├── BLOG_POST_DRAFT.md         # Marketing content
│   └── STABLE_VERSION_SYNC_PLAN.md # Sync strategy
└── data/
    └── validation_reports/        # Test results
```

### Security Model
- **Free Version**: Completely safe, no paid code
- **Paid Version**: License validation with strategy stopping on errors
- **Development Version**: Protected by .gitignore
- **License Format**: PREM2024MMXX (Paid), VIP2024XXXX (VIP)

## 💡 Key Technical Decisions

### License Validation Strategy
- **Decision**: Strict validation (errors stop strategy completely)
- **Rationale**: Prevents paid users from accidentally trading in free mode
- **Implementation**: `_validate_license_safe()` method with detailed error messages

### Parameter Restrictions
- **Free Version**: 10-100 stocks, multiples of 10
- **Paid Version**: 1-200 stocks, any quantity
- **Logic**: Implemented in separate validation methods for each tier

### Version Tiers
```python
# Tier system
1 = Free version (weekly DCA)
2 = Paid version (daily DCA + 2-layer smart adding)
3 = VIP version (reserved for premium features)
```

## 🛡️ Security Configurations

### .gitignore Protection
```
# Development versions (contains full functionality)
strategies/dca_dev_mixed.quant
strategies/*_dev_*.quant

# Sensitive data
*.key
*.license
/data/user_data/
```

### Risk Management
- **Extreme Drawdown Protection**: 50%+ switches to investment-only mode
- **Parameter Validation**: All inputs validated before execution
- **Error Handling**: Comprehensive try-catch with user-friendly messages

## 📊 Validation Results (Latest)

### Test Coverage
- **Free Version**: ✅ 100% parameter restrictions validated
- **Paid Version**: ✅ 100% license validation tested  
- **Smart Adding**: ✅ 2-layer system (10%/20% → 1.5x/2x) verified
- **Performance**: ✅ +4.1% annual return advantage confirmed

### Validation Commands
```bash
# Last successful validation: 2025-08-29 08:45:42
# Test data: 251 days SPY market data
# Results: All tests passed, no failures
```

## 🚀 Development Workflow

### Making Changes
1. Always work on development version first
2. Test with `validate_both_versions.py`
3. Update version numbers in strategy files
4. Generate validation reports
5. Commit with proper message format

### Release Process
1. Validate both versions (100% pass required)
2. Update version in strategy headers
3. Generate fresh validation reports
4. Update documentation if needed
5. Tag release with semantic versioning

## 📝 Quick Reference

### Common File Paths
- Free version: `strategies/dca_free_public.quant`
- Paid version: `strategies/dca_premium_moomoo.quant`
- Validation tool: `tools/validate_both_versions.py`
- Latest reports: `data/validation_reports/`

### Key Variables
- `version_tier`: Controls feature access (1=Free, 2=Paid, 3=VIP)
- `license_code`: User input for paid version authentication
- `interval_min`: Investment frequency (10080=weekly, 1440=daily)
- `drawdown_layers`: Smart adding thresholds [10.0, 20.0]

### Test Codes (For Validation)
```
TEST001  - Test paid version functionality
DEMO2024 - Demo paid version
TEST002  - Test VIP version (reserved)
```

## 🎯 Next Steps Planning

### Immediate Tasks
- [ ] Real market backtesting with historical data
- [ ] Performance comparison chart generation
- [ ] Blog post refinement and publishing
- [ ] User feedback collection system

### Medium Term
- [ ] Mobile configuration tool
- [ ] Additional ETF support (QQQ, IWM)
- [ ] Algorithm optimization based on user data
- [ ] Community building and support system

### Long Term
- [ ] Independent app development (8-layer system)
- [ ] Multi-asset portfolio functionality
- [ ] Machine learning strategy optimization
- [ ] Professional reporting and analytics

---

*CLAUDE.md created: 2025-08-29*  
*Last validation: 2025-08-29 08:45:42*  
*Project status: ✅ Production ready*