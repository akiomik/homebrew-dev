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

    # Create symlinks for all binary commands
    bin.install_symlink libexec/"bin/safe-chain" => "safe-chain"
    bin.install_symlink libexec/"bin/aikido-npm" => "aikido-npm"
    bin.install_symlink libexec/"bin/aikido-npx" => "aikido-npx"
    bin.install_symlink libexec/"bin/aikido-yarn" => "aikido-yarn"
    bin.install_symlink libexec/"bin/aikido-pnpm" => "aikido-pnpm"
    bin.install_symlink libexec/"bin/aikido-pnpx" => "aikido-pnpx"
    bin.install_symlink libexec/"bin/aikido-bun" => "aikido-bun"
    bin.install_symlink libexec/"bin/aikido-bunx" => "aikido-bunx"
    bin.install_symlink libexec/"bin/aikido-uv" => "aikido-uv"
    bin.install_symlink libexec/"bin/aikido-pip" => "aikido-pip"
    bin.install_symlink libexec/"bin/aikido-pip3" => "aikido-pip3"
    bin.install_symlink libexec/"bin/aikido-python" => "aikido-python"
    bin.install_symlink libexec/"bin/aikido-python3" => "aikido-python3"
  end

  test do
    system bin/"safe-chain", "--version"
    assert_match "Aikido", shell_output("#{bin}/safe-chain --help")
  end
end
