/** @jsxImportSource jsx-md */

import { execFileSync } from "child_process";
import { existsSync, readFileSync, readdirSync, statSync } from "fs";
import { join, resolve } from "path";

import {
  Badge,
  Badges,
  Bold,
  Cell,
  Center,
  Code,
  CodeBlock,
  Details,
  HR,
  Heading,
  Item,
  LineBreak,
  Link,
  List,
  Paragraph,
  Raw,
  Section,
  Sub,
  Table,
  TableHead,
  TableRow,
} from "readme";

const PROJECT = {
  name: "desks",
  oneLine: "Create and discover bounded working surfaces.",
  tagline: "A desk is a place to work, not a theory of who sits there.",
  license: "MIT",
};

const REPO_DIR = resolve(import.meta.dirname);
const TASK_DIR = join(REPO_DIR, ".mise/tasks");
const TEST_DIR = join(REPO_DIR, "test");
const WORKFLOW = join(REPO_DIR, ".github/workflows/test.yml");

interface TaskInfo {
  name: string;
  description: string;
}

function read(path: string): string {
  return readFileSync(path, "utf8");
}

function walkFiles(dir: string, predicate: (path: string) => boolean): string[] {
  if (!existsSync(dir)) return [];

  const results: string[] = [];
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const full = join(dir, entry.name);
    if (entry.isDirectory()) {
      results.push(...walkFiles(full, predicate));
    } else if (predicate(full)) {
      results.push(full);
    }
  }
  return results;
}

function discoverTasks(dir = TASK_DIR, prefix = ""): TaskInfo[] {
  if (!existsSync(dir)) return [];

  const tasks: TaskInfo[] = [];
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    if (entry.name.startsWith(".")) continue;
    const full = join(dir, entry.name);
    const name = prefix ? `${prefix}:${entry.name}` : entry.name;

    if (entry.isDirectory()) {
      tasks.push(...discoverTasks(full, name));
      continue;
    }

    const mode = statSync(full).mode;
    if ((mode & 0o111) === 0) continue;

    const src = read(full);
    const description = src.match(/^#MISE description="(.+)"$/m)?.[1] ?? "";
    tasks.push({ name, description });
  }

  return tasks.sort((a, b) => a.name.localeCompare(b.name));
}

function countBatsTests(): number {
  return walkFiles(TEST_DIR, (path) => path.endsWith(".bats"))
    .map(read)
    .join("\n")
    .match(/@test\s+"/g)?.length ?? 0;
}

function configuredLints(): string[] {
  const miseToml = read(join(REPO_DIR, "mise.toml"));
  const start = miseToml.indexOf("[_.codebase]");
  if (start === -1) return [];

  const lines = miseToml.slice(start).split("\n");
  const block: string[] = [];
  for (const [index, line] of lines.entries()) {
    if (index > 0 && line.startsWith("[")) break;
    block.push(line);
  }

  const list = block.join("\n").match(/lint\s*=\s*\[([\s\S]*?)\]/)?.[1] ?? "";
  const configured = [...list.matchAll(/"([^"]+)"/g)].map((match) => match[1]);
  if (!configured.some((rule) => rule.startsWith("@"))) return configured;

  const memberships = new Map<string, string[]>();
  let currentGroup = "";
  const groups = execFileSync("codebase", ["lint:groups"], {
    cwd: REPO_DIR,
    encoding: "utf8",
  });
  for (const line of groups.split("\n")) {
    if (line.startsWith("@")) {
      currentGroup = line;
      memberships.set(currentGroup, []);
    } else if (currentGroup && line.startsWith("  ")) {
      memberships.get(currentGroup)!.push(line.trim());
    }
  }

  return [...new Set(configured.flatMap((rule) => memberships.get(rule) ?? [rule]))];
}

function workflowOses(): string[] {
  if (!existsSync(WORKFLOW)) return [];
  const match = read(WORKFLOW).match(/os:\s*\[([^\]]+)\]/);
  if (!match) return [];
  return match[1].split(",").map((os) => os.trim()).filter(Boolean);
}

function status(path: string): string {
  return existsSync(join(REPO_DIR, path)) ? "✓" : "missing";
}

const tasks = discoverTasks();
const testCount = countBatsTests();
const lints = configuredLints();
const oses = workflowOses();

const scaffold = [
  ["mise.toml", "tools, settings, and codebase lint config"],
  ["README.tsx", "programmable README source"],
  ["CONTRIBUTING.md", "repo-entry orientation surface"],
  [".mise/tasks/new", "create a desk"],
  [".mise/tasks/mine", "resolve the current desk"],
  [".mise/tasks/list", "list accessible desks"],
  [".mise/tasks/show", "show a desk registry"],
  [".mise/tasks/path", "print a desk root"],
  [".mise/tasks/test", "canonical BATS runner"],
  [".mise/tasks/doctor", "local health check plus hook hint"],
  [".github/workflows/test.yml", "Ubuntu/macOS CI"],
  ["test/", "BATS smoke coverage"],
  ["lib/", "shared runtime code starts here when needed"],
];

const readme = (
  <>
    <Center>
      <Heading level={1}>{PROJECT.name}</Heading>

      <Paragraph>
        <Bold>{PROJECT.oneLine}</Bold>
      </Paragraph>

      <Paragraph>{PROJECT.tagline}</Paragraph>

      <Badges>
        <Badge label="shape" value="mise + BATS" color="4EAA25" logo="gnubash" logoColor="white" />
        <Badge label="tests" value={`${testCount}`} color="brightgreen" href="test/" />
        <Badge label="lints" value={`${lints.length}`} color="blue" />
        <Badge label="README" value="TSX" color="f472b6" />
        <Badge label="License" value={PROJECT.license} color="blue" href="LICENSE" />
      </Badges>
    </Center>

    <LineBreak />

    <Section title="What this is">
      <Paragraph>
        <Code>desks</Code>
        {" creates small, discoverable filesystem work surfaces. A desk has an id, a root path, and a tiny "}
        <Code>.desk/registry.json</Code>
        {" file. Higher-level tools can decide whether that surface belongs to an agent, a shell, a project, or something else."}
      </Paragraph>

      <Paragraph>
        {"The first slice is intentionally generic: create desks, find the current desk, list accessible desks, inspect a registry, and print a desk path. Briefs, agent-home preparation, session launch, and fold harvest policy stay outside core for now."}
      </Paragraph>
    </Section>

    <Section title="Quick start">
      <CodeBlock lang="bash">{`# Intended installed usage after desks is registered with shiv:
# [tools]
# "shiv:desks" = "0.1"
# Then, after mise install, use the installed shim:
export DESKS_ROOT=/tmp/desks-demo
desk=$(desks new --id demo)
DESK_ROOT="$desk" desks mine
DESK_ROOT="$desk" desks mine --json

desks list
desks show demo
desks path demo

# Contributing to this repo still uses mise:
gh repo clone KnickKnackLabs/desks
cd desks
mise trust && mise install
mise run test
mise run doctor`}</CodeBlock>
    </Section>

    <Section title="Goodies baked in">
      <Table>
        <TableHead>
          <Cell>Goodie</Cell>
          <Cell>Why it exists</Cell>
          <Cell>Where</Cell>
        </TableHead>
        <TableRow>
          <Cell>Generic core</Cell>
          <Cell>Core metadata does not know about agents, sessions, homes, briefs, or chat.</Cell>
          <Cell><Code>.desk/registry.json</Code></Cell>
        </TableRow>
        <TableRow>
          <Cell>Generated README</Cell>
          <Cell>TSX can count tests, list tasks, and keep docs honest in CI.</Cell>
          <Cell><Code>README.tsx</Code></Cell>
        </TableRow>
        <TableRow>
          <Cell>Doctor hook check</Cell>
          <Cell>Local pre-commit hooks are clone-local, so the repo can report them without pretending they are tracked.</Cell>
          <Cell><Code>mise run doctor</Code></Cell>
        </TableRow>
        <TableRow>
          <Cell>Convention lints</Cell>
          <Cell>Best-practice drift gets caught as code, not folklore.</Cell>
          <Cell><Code>[_.codebase].lint</Code></Cell>
        </TableRow>
        <TableRow>
          <Cell>Real test path</Cell>
          <Cell>BATS tests call tasks through <Code>mise run</Code>, not raw scripts.</Cell>
          <Cell><Code>test/test_helper.bash</Code></Cell>
        </TableRow>
        <TableRow>
          <Cell>Mac + Linux CI</Cell>
          <Cell>Bash and tooling differences show up before merge.</Cell>
          <Cell>{oses.join(" + ") || "workflow pending"}</Cell>
        </TableRow>
      </Table>
    </Section>

    <Section title="Scaffold inventory">
      <Table>
        <TableHead>
          <Cell>Path</Cell>
          <Cell>Status</Cell>
          <Cell>Purpose</Cell>
        </TableHead>
        {scaffold.map(([path, purpose]) => (
          <TableRow>
            <Cell><Code>{path}</Code></Cell>
            <Cell>{status(path)}</Cell>
            <Cell>{purpose}</Cell>
          </TableRow>
        ))}
      </Table>
    </Section>

    <Section title="Tasks">
      <Table>
        <TableHead>
          <Cell>Task</Cell>
          <Cell>Description</Cell>
        </TableHead>
        {tasks.map((task) => (
          <TableRow>
            <Cell><Code>{`mise run ${task.name}`}</Code></Cell>
            <Cell>{task.description}</Cell>
          </TableRow>
        ))}
      </Table>
    </Section>

    <Section title="Core boundary">
      <List ordered>
        <Item><Code>desks</Code> owns desk ids, roots, discovery, and minimal registry metadata.</Item>
        <Item>It does not own agent identity, session identity, home checkout preparation, desk briefs, <Code>chat</Code> transport, or fold harvest policy.</Item>
        <Item>Callers can put their own files under a desk after creating it.</Item>
        <Item>Installed usage goes through the shiv-provided <Code>desks</Code> shim; repo tests use <Code>mise run</Code> only to exercise that task path locally.</Item>
        <Item>Tasks use <Code>$MISE_CONFIG_ROOT</Code> inside the repo and <Code>DESKS_CALLER_PWD</Code> for caller-cwd discovery from the installed shim.</Item>
      </List>
    </Section>

    <Details summary="Current convention checks">
      <Paragraph>
        {"This repo currently asks "}
        <Link href="https://github.com/KnickKnackLabs/codebase">codebase</Link>
        {" to run these lint rules:"}
      </Paragraph>
      <CodeBlock>{lints.join("\n")}</CodeBlock>
    </Details>

    <Section title="Validation">
      <CodeBlock lang="bash">{`mise run test
codebase lint "$PWD"
readme build --check
git diff --check`}</CodeBlock>

      <Paragraph>
        {"The starter suite currently has "}
        <Bold>{`${testCount} tests`}</Bold>
        {" and "}
        <Bold>{`${tasks.length} public tasks`}</Bold>
        {". Those numbers are read from the repo at README build time."}
      </Paragraph>
    </Section>

    <Center>
      <HR />
      <Sub>
        {"This README was generated from "}
        <Code>README.tsx</Code>
        {" with "}
        <Link href="https://github.com/KnickKnackLabs/readme">KnickKnackLabs/readme</Link>
        {"."}
        <Raw>{"<br />"}</Raw>
        {"A desk is useful before it knows who will sit down."}
      </Sub>
    </Center>
  </>
);

console.log(readme);
