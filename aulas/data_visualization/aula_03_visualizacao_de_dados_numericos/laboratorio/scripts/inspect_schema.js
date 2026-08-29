import { writeFile } from 'node:fs/promises';
import pg from 'pg';

const outputPath = new URL('../docs/00_catalogo_banco.md', import.meta.url);
const databaseUrl = process.env.DATABASE_URL || process.env.POSTGRES_URL;

if (!databaseUrl) {
  console.error('DATABASE_URL não configurada. Cadastre o secret no Codespaces e recrie o ambiente.');
  process.exitCode = 1;
} else {
  const pool = new pg.Pool({
    connectionString: databaseUrl,
    max: 1,
    statement_timeout: 5000,
    query_timeout: 7000,
    ssl: { rejectUnauthorized: false }
  });

  try {
    const [columns, constraints] = await Promise.all([
      pool.query({
        text: `SELECT table_schema, table_name, ordinal_position, column_name, data_type, is_nullable
          FROM information_schema.columns
          WHERE table_schema IN ('public', 'bi_aula02')
          ORDER BY table_schema, table_name, ordinal_position`
      }),
      pool.query({
        text: `SELECT tc.table_schema, tc.table_name, tc.constraint_type, kcu.column_name,
            ccu.table_schema AS referenced_schema, ccu.table_name AS referenced_table,
            ccu.column_name AS referenced_column
          FROM information_schema.table_constraints tc
          LEFT JOIN information_schema.key_column_usage kcu
            ON tc.constraint_name = kcu.constraint_name AND tc.table_schema = kcu.table_schema
          LEFT JOIN information_schema.constraint_column_usage ccu
            ON tc.constraint_name = ccu.constraint_name AND tc.table_schema = ccu.table_schema
          WHERE tc.table_schema IN ('public', 'bi_aula02')
            AND tc.constraint_type IN ('PRIMARY KEY', 'FOREIGN KEY', 'UNIQUE')
          ORDER BY tc.table_schema, tc.table_name, tc.constraint_type, kcu.ordinal_position`
      })
    ]);

    const lines = [
      '# Catálogo do banco — Aula 03',
      '',
      `Gerado em ${new Date().toISOString()}. O arquivo contém metadados, não contém credenciais nem linhas de negócio.`,
      '',
      '## Colunas',
      '',
      '| Schema | Tabela ou view | Posição | Coluna | Tipo | Aceita nulo |',
      '|---|---|---:|---|---|---|',
      ...columns.rows.map((row) => `| ${row.table_schema} | ${row.table_name} | ${row.ordinal_position} | ${row.column_name} | ${row.data_type} | ${row.is_nullable} |`),
      '',
      '## Restrições declaradas',
      '',
      constraints.rows.length
        ? '| Schema | Tabela | Tipo | Coluna | Referência |\n|---|---|---|---|---|\n' + constraints.rows.map((row) => {
          const reference = row.referenced_table ? `${row.referenced_schema}.${row.referenced_table}.${row.referenced_column}` : '—';
          return `| ${row.table_schema} | ${row.table_name} | ${row.constraint_type} | ${row.column_name ?? '—'} | ${reference} |`;
        }).join('\n')
        : 'Nenhuma chave foi declarada no catálogo. Isso não prova ausência de relacionamento; exige validação por cardinalidade e domínio.',
      '',
      '## Questões para validação humana',
      '',
      '- Qual é o grão de cada tabela ou view?',
      '- Quais colunas parecem chaves apenas pelo nome e ainda precisam de teste?',
      '- Uma junção proposta preserva a quantidade esperada de linhas ou cria fanout?',
      '- Qual data representa compra, aprovação, envio, entrega e previsão?',
      '- Qual métrica pode ser somada e qual exige contagem distinta, mediana ou denominador?',
      ''
    ];

    await writeFile(outputPath, lines.join('\n'), 'utf8');
    console.log(`Catálogo gravado em ${outputPath.pathname}`);
  } catch {
    console.error('Não foi possível ler o catálogo. Confirme acesso somente leitura, SSL e disponibilidade do banco.');
    process.exitCode = 1;
  } finally {
    await pool.end();
  }
}
