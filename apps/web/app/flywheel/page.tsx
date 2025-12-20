"use client";

import Link from "next/link";
import { useState } from "react";
import {
  ArrowLeft,
  Terminal,
  ChevronRight,
  Zap,
  GitBranch,
  Cpu,
  Layers,
  Workflow,
  Target,
  ExternalLink,
  LayoutGrid,
  ShieldCheck,
  Mail,
  Bug,
  Brain,
  Search,
  KeyRound,
  Star,
  Copy,
  Check,
  Sparkles,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import FlywheelVisualization from "@/components/flywheel-visualization";
import { flywheelTools, flywheelDescription } from "@/lib/flywheel";

const iconMap: Record<string, React.ComponentType<{ className?: string }>> = {
  LayoutGrid,
  ShieldCheck,
  Mail,
  GitBranch,
  Bug,
  Brain,
  Search,
  KeyRound,
};

function PhilosophyCard({
  title,
  description,
  icon: Icon,
  delay,
}: {
  title: string;
  description: string;
  icon: React.ComponentType<{ className?: string }>;
  delay: number;
}) {
  return (
    <div
      className="group relative overflow-hidden rounded-2xl border border-border/50 bg-card/50 p-6 backdrop-blur-sm transition-all duration-300 hover:border-primary/30 hover:shadow-lg card-hover opacity-0 animate-slide-up"
      style={{ animationDelay: `${delay}s`, animationFillMode: "forwards" }}
    >
      <div className="absolute -right-20 -top-20 h-40 w-40 rounded-full bg-primary/10 blur-3xl opacity-0 transition-opacity duration-500 group-hover:opacity-100" />
      <div className="relative z-10">
        <div className="mb-4 inline-flex rounded-xl bg-primary/10 p-3 text-primary">
          <Icon className="h-6 w-6" />
        </div>
        <h3 className="mb-2 text-lg font-semibold tracking-tight text-foreground">{title}</h3>
        <p className="text-sm leading-relaxed text-muted-foreground">{description}</p>
      </div>
    </div>
  );
}

function ToolGridCard({ tool, index }: { tool: (typeof flywheelTools)[0]; index: number }) {
  const Icon = iconMap[tool.icon] || Zap;
  const [copied, setCopied] = useState(false);

  const copyInstall = () => {
    if (tool.installCommand) {
      navigator.clipboard.writeText(tool.installCommand);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    }
  };

  return (
    <div
      className="group relative overflow-hidden rounded-2xl border border-border/50 bg-card/50 p-6 backdrop-blur-sm transition-all duration-300 hover:border-primary/30 card-hover opacity-0 animate-slide-up"
      style={{ animationDelay: `${0.1 + index * 0.05}s`, animationFillMode: "forwards" }}
    >
      {/* Gradient glow */}
      <div
        className={`absolute -right-20 -top-20 h-40 w-40 rounded-full opacity-0 blur-3xl transition-opacity duration-500 group-hover:opacity-30 bg-gradient-to-br ${tool.color}`}
      />

      <div className="relative z-10">
        {/* Header */}
        <div className="flex items-start justify-between gap-3 mb-4">
          <div className="flex items-center gap-3">
            <div className={`flex h-12 w-12 items-center justify-center rounded-xl bg-gradient-to-br ${tool.color}`}>
              <Icon className="h-6 w-6 text-white" />
            </div>
            <div>
              <h3 className="font-semibold text-foreground">{tool.name}</h3>
              <p className="text-xs text-muted-foreground">{tool.tagline}</p>
            </div>
          </div>
          {tool.stars && (
            <div className="flex items-center gap-1 rounded-full bg-amber-500/10 px-2 py-1 text-xs font-semibold text-amber-400">
              <Star className="h-3 w-3 fill-current" />
              {tool.stars >= 1000 ? `${(tool.stars / 1000).toFixed(1)}K` : tool.stars}
            </div>
          )}
        </div>

        {/* Description */}
        <p className="text-sm text-muted-foreground mb-4 line-clamp-2">{tool.description}</p>

        {/* Features */}
        <ul className="space-y-1 mb-4">
          {tool.features.slice(0, 2).map((feature, i) => (
            <li key={i} className="flex items-start gap-2 text-xs text-muted-foreground">
              <Check className="mt-0.5 h-3 w-3 shrink-0 text-primary" />
              <span className="line-clamp-1">{feature}</span>
            </li>
          ))}
        </ul>

        {/* Install command */}
        {tool.installCommand && (
          <div className="flex items-center gap-2 rounded-lg bg-muted/50 p-2 mb-4">
            <code className="flex-1 overflow-hidden text-ellipsis whitespace-nowrap text-[10px] font-mono text-muted-foreground">
              curl -fsSL ... | bash
            </code>
            <button
              onClick={copyInstall}
              className="shrink-0 rounded p-1 text-muted-foreground transition-colors hover:bg-muted hover:text-foreground"
              aria-label="Copy install command"
            >
              {copied ? <Check className="h-3 w-3 text-primary" /> : <Copy className="h-3 w-3" />}
            </button>
          </div>
        )}

        {/* Actions */}
        <div className="flex gap-2">
          <Button asChild size="sm" variant="outline" className="flex-1 text-xs">
            <a href={tool.href} target="_blank" rel="noopener noreferrer">
              GitHub
              <ExternalLink className="ml-1 h-3 w-3" />
            </a>
          </Button>
          {tool.demoUrl && (
            <Button asChild size="sm" variant="ghost" className="text-xs">
              <a href={tool.demoUrl} target="_blank" rel="noopener noreferrer">
                Demo
              </a>
            </Button>
          )}
        </div>
      </div>
    </div>
  );
}

function ConnectionDiagram() {
  return (
    <div className="overflow-x-auto pb-4">
      <div className="min-w-[600px] rounded-2xl border border-border/50 bg-card/30 p-6">
        <h3 className="text-center text-lg font-semibold text-foreground mb-6">How Tools Connect</h3>

        <div className="grid grid-cols-4 gap-4">
          {/* Row 1: Top tools */}
          <div className="col-start-2 col-span-2 flex justify-center gap-8">
            <div className="flex flex-col items-center">
              <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-gradient-to-br from-sky-400 to-blue-500">
                <LayoutGrid className="h-5 w-5 text-white" />
              </div>
              <span className="mt-2 text-xs font-bold text-foreground">NTM</span>
              <span className="text-[10px] text-muted-foreground">Spawns agents</span>
            </div>
            <div className="flex flex-col items-center">
              <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-gradient-to-br from-yellow-400 to-amber-500">
                <ShieldCheck className="h-5 w-5 text-white" />
              </div>
              <span className="mt-2 text-xs font-bold text-foreground">SLB</span>
              <span className="text-[10px] text-muted-foreground">Safety gates</span>
            </div>
          </div>

          {/* Arrow down */}
          <div className="col-span-4 flex justify-center py-2">
            <svg width="200" height="40" className="text-primary/30">
              <path d="M 50 0 L 50 30 M 150 0 L 150 30" stroke="currentColor" strokeWidth="1" strokeDasharray="4 4" />
              <path d="M 50 30 L 100 35 L 150 30" stroke="currentColor" strokeWidth="1" fill="none" />
            </svg>
          </div>

          {/* Row 2: Mail (center) */}
          <div className="col-span-4 flex justify-center">
            <div className="flex flex-col items-center">
              <div className="flex h-16 w-16 items-center justify-center rounded-xl bg-gradient-to-br from-violet-400 to-purple-500 shadow-lg shadow-violet-500/20">
                <Mail className="h-8 w-8 text-white" />
              </div>
              <span className="mt-2 text-sm font-bold text-foreground">Agent Mail</span>
              <span className="text-xs text-muted-foreground">Coordination hub</span>
            </div>
          </div>

          {/* Arrow down */}
          <div className="col-span-4 flex justify-center py-2">
            <svg width="300" height="40" className="text-primary/30">
              <path
                d="M 75 0 L 75 35 M 150 0 L 150 35 M 225 0 L 225 35"
                stroke="currentColor"
                strokeWidth="1"
                strokeDasharray="4 4"
              />
            </svg>
          </div>

          {/* Row 3: BV, UBS, CASS */}
          <div className="col-span-4 flex justify-center gap-6">
            <div className="flex flex-col items-center">
              <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-gradient-to-br from-emerald-400 to-teal-500">
                <GitBranch className="h-5 w-5 text-white" />
              </div>
              <span className="mt-2 text-xs font-bold text-foreground">BV</span>
              <span className="text-[10px] text-muted-foreground">Task graph</span>
            </div>
            <div className="flex flex-col items-center">
              <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-gradient-to-br from-rose-400 to-red-500">
                <Bug className="h-5 w-5 text-white" />
              </div>
              <span className="mt-2 text-xs font-bold text-foreground">UBS</span>
              <span className="text-[10px] text-muted-foreground">Bug scanning</span>
            </div>
            <div className="flex flex-col items-center">
              <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-gradient-to-br from-cyan-400 to-sky-500">
                <Search className="h-5 w-5 text-white" />
              </div>
              <span className="mt-2 text-xs font-bold text-foreground">CASS</span>
              <span className="text-[10px] text-muted-foreground">Search</span>
            </div>
          </div>

          {/* Arrow down */}
          <div className="col-span-4 flex justify-center py-2">
            <svg width="200" height="40" className="text-primary/30">
              <path d="M 50 0 L 100 35 L 150 0" stroke="currentColor" strokeWidth="1" strokeDasharray="4 4" />
            </svg>
          </div>

          {/* Row 4: CM */}
          <div className="col-span-4 flex justify-center">
            <div className="flex flex-col items-center">
              <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-gradient-to-br from-pink-400 to-fuchsia-500">
                <Brain className="h-5 w-5 text-white" />
              </div>
              <span className="mt-2 text-xs font-bold text-foreground">CM</span>
              <span className="text-[10px] text-muted-foreground">Memory</span>
            </div>
          </div>
        </div>

        <p className="mt-6 text-center text-xs text-muted-foreground">
          Data flows between tools creating a self-reinforcing feedback loop
        </p>
      </div>
    </div>
  );
}

export default function FlywheelPage() {
  return (
    <div className="relative min-h-screen overflow-hidden bg-background">
      {/* Background */}
      <div className="pointer-events-none absolute inset-0 bg-gradient-hero" />
      <div className="pointer-events-none absolute inset-0 bg-grid-pattern opacity-30" />

      {/* Floating orbs */}
      <div className="pointer-events-none absolute left-1/4 top-1/4 h-96 w-96 rounded-full bg-primary/10 blur-[100px] animate-pulse-glow" />
      <div
        className="pointer-events-none absolute right-1/4 bottom-1/4 h-80 w-80 rounded-full bg-[oklch(0.7_0.2_330/0.08)] blur-[80px] animate-pulse-glow"
        style={{ animationDelay: "1s" }}
      />

      {/* Navigation */}
      <nav className="relative z-20 mx-auto flex max-w-7xl items-center justify-between px-6 py-6">
        <div className="flex items-center gap-4">
          <Button asChild variant="ghost" size="sm" className="text-muted-foreground hover:text-foreground">
            <Link href="/">
              <ArrowLeft className="mr-2 h-4 w-4" />
              Back
            </Link>
          </Button>
        </div>
        <div className="flex items-center gap-2">
          <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-primary/20">
            <Terminal className="h-5 w-5 text-primary" />
          </div>
          <span className="font-mono text-lg font-bold tracking-tight">ACFS</span>
        </div>
        <div className="flex items-center gap-4">
          <Button asChild size="sm" variant="outline" className="border-primary/30 hover:bg-primary/10">
            <Link href="/wizard/os-selection">
              Get Started
              <ChevronRight className="ml-1 h-4 w-4" />
            </Link>
          </Button>
        </div>
      </nav>

      {/* Main content */}
      <main className="relative z-10">
        {/* Hero */}
        <section className="mx-auto max-w-7xl px-6 pt-12 pb-20">
          <div
            className="mb-6 inline-flex w-fit items-center gap-2 rounded-full border border-primary/30 bg-primary/10 px-4 py-1.5 text-sm text-primary opacity-0 animate-slide-up"
            style={{ animationDelay: "0.1s", animationFillMode: "forwards" }}
          >
            <Sparkles className="h-4 w-4" />
            <span>The complete multi-agent ecosystem</span>
          </div>

          <h1
            className="mb-6 font-mono text-4xl font-bold leading-tight tracking-tight sm:text-5xl lg:text-6xl opacity-0 animate-slide-up"
            style={{ animationDelay: "0.2s", animationFillMode: "forwards" }}
          >
            <span className="text-gradient-cosmic">The Flywheel</span>
          </h1>

          <p
            className="max-w-3xl text-lg leading-relaxed text-muted-foreground opacity-0 animate-slide-up"
            style={{ animationDelay: "0.3s", animationFillMode: "forwards" }}
          >
            Eight interconnected tools that transform how you work with AI coding agents. Each tool enhances the
            others, creating a self-reinforcing loop that gets more powerful the more you use it.
          </p>
        </section>

        {/* Interactive Flywheel Visualization */}
        <section className="mx-auto max-w-7xl px-6 pb-24">
          <FlywheelVisualization />
        </section>

        {/* Philosophy */}
        <section className="border-y border-border/30 bg-card/20 py-24">
          <div className="mx-auto max-w-7xl px-6">
            <div className="mb-12 text-center">
              <h2 className="mb-4 font-mono text-3xl font-bold tracking-tight text-foreground">Design Philosophy</h2>
              <p className="mx-auto max-w-2xl text-muted-foreground">
                Built from daily experience running multiple AI agents on complex software projects
              </p>
            </div>

            <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-4">
              <PhilosophyCard
                icon={Layers}
                title="Unix Philosophy"
                description="Each tool does one thing exceptionally well. They compose through standard protocols and interfaces."
                delay={0.1}
              />
              <PhilosophyCard
                icon={Cpu}
                title="Agent-First"
                description="Every tool has --robot mode or JSON output. Designed to be called by AI agents, not just humans."
                delay={0.2}
              />
              <PhilosophyCard
                icon={Workflow}
                title="Self-Reinforcing"
                description="The flywheel effect: each tool makes the others more powerful. Using three is 10x better than one."
                delay={0.3}
              />
              <PhilosophyCard
                icon={Target}
                title="Battle-Tested"
                description="Born from daily use building complex software with multiple AI agents simultaneously."
                delay={0.4}
              />
            </div>
          </div>
        </section>

        {/* Connection Diagram */}
        <section className="mx-auto max-w-7xl px-6 py-24">
          <div className="mb-12 text-center">
            <h2 className="mb-4 font-mono text-3xl font-bold tracking-tight text-foreground">System Architecture</h2>
            <p className="mx-auto max-w-2xl text-muted-foreground">
              Agent Mail sits at the center, enabling coordination between all other tools
            </p>
          </div>

          <ConnectionDiagram />
        </section>

        {/* All Tools Grid */}
        <section className="border-t border-border/30 bg-card/20 py-24">
          <div className="mx-auto max-w-7xl px-6">
            <div className="mb-12 text-center">
              <h2 className="mb-4 font-mono text-3xl font-bold tracking-tight text-foreground">All Flywheel Tools</h2>
              <p className="mx-auto max-w-2xl text-muted-foreground">
                Quick-install any tool with a single curl command
              </p>
            </div>

            <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-4">
              {flywheelTools.map((tool, index) => (
                <ToolGridCard key={tool.id} tool={tool} index={index} />
              ))}
            </div>
          </div>
        </section>

        {/* CTA */}
        <section className="mx-auto max-w-7xl px-6 py-24">
          <div className="rounded-3xl border border-primary/30 bg-gradient-to-br from-primary/10 via-card/50 to-card/30 p-12 text-center backdrop-blur-sm">
            <h2 className="mb-4 font-mono text-3xl font-bold tracking-tight text-foreground">Ready to Get Started?</h2>
            <p className="mx-auto mb-8 max-w-2xl text-muted-foreground">
              The ACFS installer sets up all flywheel tools automatically. From zero to multi-agent workflows in 30
              minutes.
            </p>
            <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
              <Button asChild size="lg" className="bg-primary text-primary-foreground">
                <Link href="/wizard/os-selection">
                  Start the Wizard
                  <ChevronRight className="ml-2 h-4 w-4" />
                </Link>
              </Button>
              <Button asChild size="lg" variant="outline">
                <a
                  href="https://github.com/Dicklesworthstone/agentic_coding_flywheel_setup"
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  <GitBranch className="mr-2 h-4 w-4" />
                  View Source
                </a>
              </Button>
            </div>
          </div>
        </section>

        {/* Footer */}
        <footer className="border-t border-border/30 py-12">
          <div className="mx-auto max-w-7xl px-6">
            <div className="flex flex-col items-center justify-between gap-6 sm:flex-row">
              <div className="flex items-center gap-2">
                <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-primary/20">
                  <Terminal className="h-4 w-4 text-primary" />
                </div>
                <span className="font-mono text-sm font-bold">ACFS</span>
              </div>

              <div className="flex items-center gap-6 text-sm text-muted-foreground">
                <a
                  href="https://github.com/Dicklesworthstone/agentic_coding_flywheel_setup"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="transition-colors hover:text-foreground"
                >
                  GitHub
                </a>
                <Link href="/" className="transition-colors hover:text-foreground">
                  Home
                </Link>
                <Link href="/wizard/os-selection" className="transition-colors hover:text-foreground">
                  Get Started
                </Link>
              </div>

              <p className="text-xs text-muted-foreground">Built for the agentic coding community</p>
            </div>
          </div>
        </footer>
      </main>
    </div>
  );
}
