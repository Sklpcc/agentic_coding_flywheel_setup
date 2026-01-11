"use client";

import { motion } from "@/components/motion";
import {
  ShieldAlert,
  Shield,
  Terminal,
  AlertTriangle,
  CheckCircle,
  XCircle,
  Zap,
  Package,
  Lightbulb,
  Clock,
  Key,
} from "lucide-react";
import {
  Section,
  Paragraph,
  CodeBlock,
  TipBox,
  Highlight,
  Divider,
  GoalBanner,
  CommandList,
  FeatureCard,
  FeatureGrid,
} from "./lesson-components";

export function DcgLesson() {
  return (
    <div className="space-y-8">
      <GoalBanner>
        Learn to use DCG to block dangerous commands before they execute.
      </GoalBanner>

      {/* What Is DCG */}
      <Section
        title="What Is DCG?"
        icon={<ShieldAlert className="h-5 w-5" />}
        delay={0.1}
      >
        <Paragraph>
          <Highlight>DCG (Destructive Command Guard)</Highlight> is a safety net
          that catches dangerous commands before they can cause damage. It works
          as a Claude Code hook, intercepting commands in real-time.
        </Paragraph>
        <Paragraph>
          Think of it as a guard at the door who checks every command before
          letting it through. Dangerous patterns like <code>rm -rf /</code>,{" "}
          <code>git reset --hard</code>, or <code>DROP TABLE</code> get blocked
          instantly.
        </Paragraph>

        <div className="mt-8">
          <FeatureGrid>
            <FeatureCard
              icon={<Zap className="h-5 w-5" />}
              title="Sub-50ms Latency"
              description="Blocks in milliseconds, never slows you down"
              gradient="from-yellow-500/20 to-amber-500/20"
            />
            <FeatureCard
              icon={<Package className="h-5 w-5" />}
              title="50+ Protection Packs"
              description="Git, filesystem, database, K8s, cloud"
              gradient="from-primary/20 to-violet-500/20"
            />
            <FeatureCard
              icon={<Shield className="h-5 w-5" />}
              title="Fail-Open Design"
              description="Never blocks your workflow on errors"
              gradient="from-emerald-500/20 to-teal-500/20"
            />
            <FeatureCard
              icon={<Key className="h-5 w-5" />}
              title="Allow-Once Bypass"
              description="Legitimate bypasses with time-limited codes"
              gradient="from-red-500/20 to-rose-500/20"
            />
          </FeatureGrid>
        </div>
      </Section>

      <Divider />

      {/* Why DCG Matters */}
      <Section
        title="Why DCG Matters"
        icon={<AlertTriangle className="h-5 w-5" />}
        delay={0.15}
      >
        <motion.div
          initial={{ opacity: 0, scale: 0.95 }}
          animate={{ opacity: 1, scale: 1 }}
          className="relative p-6 rounded-2xl border border-red-500/30 bg-gradient-to-br from-red-500/10 to-rose-500/10"
        >
          <div className="flex items-center gap-4">
            <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-red-500/20 text-red-400">
              <AlertTriangle className="h-6 w-6" />
            </div>
            <div>
              <p className="text-lg font-bold text-white">
                AI agents occasionally make destructive mistakes.
              </p>
              <p className="text-white/60 mt-1">
                Hours of uncommitted work can vanish in seconds. DCG catches
                these mistakes before damage occurs.
              </p>
            </div>
          </div>
        </motion.div>

        <div className="mt-6 space-y-4">
          <BlockedCommandCard
            command="git reset --hard HEAD~5"
            reason="Destroys uncommitted work and recent commits"
            alternative="git stash && git revert HEAD~5"
          />
          <BlockedCommandCard
            command="rm -rf /data/projects/*"
            reason="Deletes source code recursively"
            alternative="mv to archive or use git clean"
          />
          <BlockedCommandCard
            command="DROP TABLE users;"
            reason="Destroys database data permanently"
            alternative="TRUNCATE or create backup first"
          />
        </div>
      </Section>

      <Divider />

      {/* Essential Commands */}
      <Section
        title="Essential Commands"
        icon={<Terminal className="h-5 w-5" />}
        delay={0.2}
      >
        <CommandList
          commands={[
            {
              command: "dcg test 'command'",
              description: "Check if a command would be blocked",
            },
            {
              command: "dcg test 'command' --explain",
              description: "Get detailed explanation of why",
            },
            {
              command: "dcg packs",
              description: "List all protection packs",
            },
            {
              command: "dcg packs --enabled",
              description: "Show only enabled packs",
            },
            {
              command: "dcg doctor",
              description: "Check DCG installation health",
            },
            {
              command: "dcg install",
              description: "Register Claude Code hook",
            },
          ]}
        />
      </Section>

      <Divider />

      {/* Allow-Once Workflow */}
      <Section
        title="Allow-Once Workflow"
        icon={<Key className="h-5 w-5" />}
        delay={0.25}
      >
        <Paragraph>
          Sometimes you legitimately need to run a blocked command. DCG provides
          the <Highlight>allow-once</Highlight> workflow for controlled bypasses.
        </Paragraph>

        <div className="mt-6 space-y-4">
          <WorkflowStep
            step={1}
            title="Command Gets Blocked"
            description="DCG blocks the dangerous command and provides a short code"
          />
          <WorkflowStep
            step={2}
            title="Use Allow-Once"
            description="Run dcg allow-once CODE with the provided code"
          />
          <WorkflowStep
            step={3}
            title="Run Command"
            description="The command can now execute (within time limit)"
          />
        </div>

        <div className="mt-6">
          <CodeBlock language="bash">
            {`# Command gets blocked with code ABC-123
$ dcg allow-once ABC-123

# Now the command will be allowed (for 60 seconds)`}
          </CodeBlock>
        </div>

        <div className="mt-6">
          <TipBox variant="warning">
            Allow-once codes expire after a short time. Use them promptly and
            only when you&apos;re sure the command is safe in context.
          </TipBox>
        </div>
      </Section>

      <Divider />

      {/* DCG + SLB */}
      <Section
        title="DCG + SLB: Defense in Depth"
        icon={<Shield className="h-5 w-5" />}
        delay={0.3}
      >
        <Paragraph>
          DCG and SLB work together to provide layered safety:
        </Paragraph>

        <div className="mt-8">
          <FeatureGrid columns={2}>
            <FeatureCard
              icon={<ShieldAlert className="h-5 w-5" />}
              title="DCG: Pre-Execution"
              description="Blocks obvious destructive patterns instantly"
              gradient="from-red-500/20 to-rose-500/20"
            />
            <FeatureCard
              icon={<Shield className="h-5 w-5" />}
              title="SLB: Post-Proposal"
              description="Human approval for contextual risks"
              gradient="from-amber-500/20 to-orange-500/20"
            />
          </FeatureGrid>
        </div>

        <div className="mt-6">
          <TipBox variant="tip">
            DCG catches the obvious mistakes. SLB catches the subtle ones that
            require human judgment about context and intent.
          </TipBox>
        </div>
      </Section>
    </div>
  );
}

// Helper Components

function BlockedCommandCard({
  command,
  reason,
  alternative,
}: {
  command: string;
  reason: string;
  alternative: string;
}) {
  return (
    <motion.div
      initial={{ opacity: 0, x: -10 }}
      animate={{ opacity: 1, x: 0 }}
      className="p-4 rounded-xl border border-red-500/20 bg-gradient-to-r from-red-500/5 to-transparent"
    >
      <div className="flex items-start gap-3">
        <XCircle className="h-5 w-5 text-red-400 mt-0.5 flex-shrink-0" />
        <div className="flex-1">
          <code className="text-red-300 font-mono text-sm">{command}</code>
          <p className="text-white/60 text-sm mt-1">{reason}</p>
          <div className="flex items-center gap-2 mt-2">
            <CheckCircle className="h-4 w-4 text-emerald-400" />
            <span className="text-emerald-300 text-sm">{alternative}</span>
          </div>
        </div>
      </div>
    </motion.div>
  );
}

function WorkflowStep({
  step,
  title,
  description,
}: {
  step: number;
  title: string;
  description: string;
}) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay: step * 0.1 }}
      className="flex items-start gap-4"
    >
      <div className="flex h-8 w-8 items-center justify-center rounded-full bg-primary/20 text-primary font-bold text-sm flex-shrink-0">
        {step}
      </div>
      <div>
        <p className="font-semibold text-white">{title}</p>
        <p className="text-white/60 text-sm">{description}</p>
      </div>
    </motion.div>
  );
}
