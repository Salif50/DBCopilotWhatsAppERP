import fs from 'node:fs';

const files = process.argv.slice(2);
if (!files.length) {
  console.error('Usage: node scripts/validate-workflows.mjs workflow.json [...]');
  process.exit(2);
}

let failed = false;

for (const file of files) {
  const workflow = JSON.parse(fs.readFileSync(file, 'utf8'));
  const names = workflow.nodes.map((node) => node.name);
  const nameSet = new Set(names);
  const ids = new Set();
  const errors = [];

  if (nameSet.size !== names.length) errors.push('noms de nœuds dupliqués');

  for (const node of workflow.nodes) {
    if (ids.has(node.id)) errors.push(`ID dupliqué: ${node.id}`);
    ids.add(node.id);
    const source = node.parameters?.jsCode;
    if (typeof source === 'string') {
      try {
        const AsyncFunction = Object.getPrototypeOf(async function () {}).constructor;
        new AsyncFunction(source);
      } catch (error) {
        errors.push(`JavaScript invalide dans ${node.name}: ${error.message}`);
      }
    }
  }

  const adjacent = new Map();
  for (const [source, groups] of Object.entries(workflow.connections ?? {})) {
    if (!nameSet.has(source)) errors.push(`source absente: ${source}`);
    if (!adjacent.has(source)) adjacent.set(source, []);
    for (const outputs of Object.values(groups)) {
      for (const output of outputs) {
        for (const connection of output) {
          if (!nameSet.has(connection.node)) errors.push(`cible absente: ${connection.node}`);
          adjacent.get(source).push(connection.node);
        }
      }
    }
  }

  const roots = workflow.nodes
    .filter((node) => /(?:webhook|scheduleTrigger|errorTrigger)$/.test(node.type))
    .map((node) => node.name);
  const reachable = new Set(roots);
  const queue = [...roots];
  while (queue.length) {
    const source = queue.shift();
    for (const target of adjacent.get(source) ?? []) {
      if (!reachable.has(target)) {
        reachable.add(target);
        queue.push(target);
      }
    }
  }
  const unreachable = names.filter((name) => !reachable.has(name));
  if (unreachable.length) errors.push(`nœuds inaccessibles: ${unreachable.join(', ')}`);

  if (errors.length) {
    failed = true;
    console.error(`FAIL ${file}\n- ${errors.join('\n- ')}`);
  } else {
    const codeNodes = workflow.nodes.filter(
      (node) => typeof node.parameters?.jsCode === 'string',
    ).length;
    console.log(`OK ${file}: ${workflow.nodes.length} nœuds, ${codeNodes} blocs JavaScript`);
  }
}

if (failed) process.exit(1);
