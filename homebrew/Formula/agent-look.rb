class AgentLook < Formula
  desc "Screenshot scanner & renamer MCP server — works with Claude, Gemini, Codex"
  homepage "https://github.com/ashrocket/agent-look"
  url "https://github.com/ashrocket/agent-look/archive/refs/tags/v0.2.0.tar.gz"
  # sha256 "REPLACE_WITH_ACTUAL_SHA256_AFTER_TAGGING"
  license "MIT"

  depends_on :macos
  depends_on "node"

  def install
    # Install npm dependencies for the MCP server
    cd "mcp" do
      system "npm", "install", *std_npm_args(prefix: false)
    end

    # Install everything to libexec
    libexec.install Dir["*"]
    libexec.install ".claude-plugin" if Dir.exist?(".claude-plugin")

    # Create wrapper scripts in bin/
    (bin/"agent-look").write <<~SH
      #!/bin/bash
      exec node "#{libexec}/bin/agent-look.js" "$@"
    SH

    (bin/"agent-look-mcp").write <<~SH
      #!/bin/bash
      exec node "#{libexec}/mcp/server.js" "$@"
    SH
  end

  def post_install
    # Register MCP server in detected AI tool configs
    system bin/"agent-look", "register"
  end

  def caveats
    <<~EOS
      agent-look MCP server has been registered in detected AI tool configs.

      To check registration status:
        agent-look status

      To manually register/unregister:
        agent-look register
        agent-look unregister

      The MCP server can also be started directly:
        agent-look serve
        agent-look-mcp

      For Claude Code, you can also install as a plugin:
        claude plugin add #{libexec}
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/agent-look --version")
  end
end
