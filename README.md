# homebrew-dev

Personal Homebrew tap for development tools and libraries.

## Usage

```bash
# Add tap
brew tap akiomik/dev

# Install packages
brew install safe-chain
```

## Available Packages

### safe-chain

Security tool by [Aikido Security](https://github.com/AikidoSec/safe-chain) that wraps package managers (npm, yarn, pnpm, etc.) for secure dependency management.

📦 [npm package](https://www.npmjs.com/package/@aikidosec/safe-chain) | 🔗 [GitHub repository](https://github.com/AikidoSec/safe-chain)

**Available commands after installation:**
- `safe-chain` - Main command
- `aikido-npm`, `aikido-npx` - npm/npx wrappers
- `aikido-yarn` - yarn wrapper
- `aikido-pnpm`, `aikido-pnpx` - pnpm wrappers
- `aikido-bun`, `aikido-bunx` - bun wrappers
- `aikido-uv` - uv wrapper
- `aikido-pip`, `aikido-pip3` - pip wrappers
- `aikido-python`, `aikido-python3` - python wrappers

## License

This repository is licensed under the [Apache License 2.0](LICENSE).

Individual packages have their own licenses. See each Formula file for package-specific license information.