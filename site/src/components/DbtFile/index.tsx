import React from 'react';
import CodeBlock from '@theme/CodeBlock';
import {REPO_BLOB} from '@site/src/data/kimball';
import styles from './styles.module.css';

// Bundle every SQL / YAML file in the dbt project as raw text at build time,
// so lessons always show the exact code that `dbt build` runs.
// eslint-disable-next-line @typescript-eslint/no-var-requires
const ctx = (require as any).context('!!raw-loader!../../../../dbt', true, /^\.\/((models|macros|snapshots|tests|analyses)\/.*\.(sql|yml)|dbt_project\.yml|packages\.yml)$/);

const files: Record<string, string> = {};
ctx.keys().forEach((k: string) => {
  const mod = ctx(k);
  files[k.replace(/^\.\//, '')] = (mod.default ?? mod) as string;
});

type Props = {
  /** Path relative to the dbt/ directory, e.g. "models/marts/core/dim_product.sql" */
  path: string;
  /** Optional title override (defaults to the file name). */
  title?: string;
  /** Show only lines [from, to] (1-based, inclusive). */
  lines?: [number, number];
  /** Wrap in a collapsed <details>. */
  collapsed?: boolean;
  /** Prism line-highlight spec, e.g. "{3,7-9}" (relative to the shown excerpt). */
  highlight?: string;
};

export default function DbtFile({path, title, lines, collapsed = false, highlight}: Props) {
  const source = files[path];
  if (source === undefined) {
    throw new Error(`DbtFile: no such file in dbt project: ${path}`);
  }
  let code = source.replace(/\n$/, '');
  if (lines) {
    const all = code.split('\n');
    if (lines[0] < 1 || lines[1] > all.length || lines[0] > lines[1]) {
      // Fail the build so excerpts never silently drift when a model is edited.
      throw new Error(`DbtFile: lines ${lines[0]}-${lines[1]} out of range for ${path} (${all.length} lines)`);
    }
    code = all.slice(lines[0] - 1, lines[1]).join('\n');
  }
  const language = path.endsWith('.yml') ? 'yaml' : 'sql';
  const name = title ?? path.split('/').pop();
  const meta = highlight ? highlight : undefined;
  const block = (
    <div className={styles.wrap}>
      <CodeBlock language={language} title={name} metastring={meta} showLineNumbers>
        {code}
      </CodeBlock>
      <div className={styles.source}>
        <code>dbt/{path}</code>
        {lines ? ` (lines ${lines[0]} to ${lines[1]})` : ''} ·{' '}
        <a href={`${REPO_BLOB}/dbt/${path}`} target="_blank" rel="noopener noreferrer">
          view on GitHub
        </a>
      </div>
    </div>
  );
  if (collapsed) {
    return (
      <details className={styles.details}>
        <summary>
          Show <code>{name}</code>
        </summary>
        {block}
      </details>
    );
  }
  return block;
}
