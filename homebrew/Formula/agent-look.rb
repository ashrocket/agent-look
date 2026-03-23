class AgentLook < Formula
  desc "Screenshot scanner & renamer MCP server — works with Claude, Gemini, Codex"
  homepage "https://github.com/ashrocket/agent-look"
  url "https://github.com/ashrocket/agent-look/archive/refs/tags/v0.2.0.tar.gz"
  sha256 "b193b297f608d9f3e4f1a33e714794570497b82b6ee31e3692be881b154a2351"
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

  def caveats
    <<~EOS
      To register the MCP server in your AI tools, run:
        agent-look register

      This wires up Claude Desktop, Claude Code, Gemini CLI, and Codex.

      Other commands:
        agent-look status       Check registration status
        agent-look unregister   Remove from all AI tools
        agent-look serve        Start the MCP server directly

      For Claude Code, you can also install as a plugin:
        claude plugin add #{libexec}
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/agent-look --version")
  end
end
