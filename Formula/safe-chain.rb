class SafeChain < Formula
  desc "The Aikido Safe Chain wraps around package managers to provide security scanning"
  homepage "https://github.com/AikidoSec/safe-chain#readme"
  url "https://registry.npmjs.org/@aikidosec/safe-chain/-/safe-chain-1.1.10.tgz"
  sha256 "4daf7dc4a9cfbeea9d23ee5ebc37902c2d2431104b795eb7c7bdc9d041454e55"
  license "AGPL-3.0-or-later"
  version "1.1.10"

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    
    # Create symlinks for all the binary commands
    bin.install_symlink libexec/"bin/safe-chain.js" => "safe-chain"
    bin.install_symlink libexec/"bin/aikido-npm.js" => "aikido-npm"
    bin.install_symlink libexec/"bin/aikido-npx.js" => "aikido-npx"
    bin.install_symlink libexec/"bin/aikido-yarn.js" => "aikido-yarn"
    bin.install_symlink libexec/"bin/aikido-pnpm.js" => "aikido-pnpm"
    bin.install_symlink libexec/"bin/aikido-pnpx.js" => "aikido-pnpx"
    bin.install_symlink libexec/"bin/aikido-bun.js" => "aikido-bun"
    bin.install_symlink libexec/"bin/aikido-bunx.js" => "aikido-bunx"
    bin.install_symlink libexec/"bin/aikido-uv.js" => "aikido-uv"
    bin.install_symlink libexec/"bin/aikido-pip.js" => "aikido-pip"
    bin.install_symlink libexec/"bin/aikido-pip3.js" => "aikido-pip3"
    bin.install_symlink libexec/"bin/aikido-python.js" => "aikido-python"
    bin.install_symlink libexec/"bin/aikido-python3.js" => "aikido-python3"
  end

  test do
    system bin/"safe-chain", "--version"
    assert_match "Aikido", shell_output("#{bin}/safe-chain --help")
  end
end