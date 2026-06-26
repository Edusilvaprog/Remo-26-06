-- =============================================================================
-- PLORIX — SQL para Supabase (projeto Remoterapia-APP)
-- =============================================================================
--
-- COMO EXECUTAR (siga na ordem):
--   1. https://supabase.com/dashboard → projeto Remoterapia-APP
--   2. Menu esquerdo: SQL Editor
--   3. Botão: New query  (Nova consulta)
--   4. Apague TUDO na caixa branca
--   5. Copie ESTE FICHEIRO INTEIRO (Ctrl+A, Ctrl+C) e cole (Ctrl+V)
--   6. Botão verde RUN (ou Ctrl+Enter)
--   7. No painel Results deve aparecer UMA linha: id = 1
--
-- Se der erro: execute só o "BLOCO A" abaixo, Run, depois o "BLOCO B", Run.
-- =============================================================================


-- ############## BLOCO A — Apagar tabela antiga (pode correr sozinho) ##############
DROP TABLE IF EXISTS public.plorix_sync CASCADE;


-- ############## BLOCO B — Criar tabela + permissões (cole com o Bloco A ou depois) ##############

CREATE TABLE public.plorix_sync (
  id          integer PRIMARY KEY,
  payload     jsonb NOT NULL DEFAULT '{}'::jsonb,
  updated_at  timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.plorix_sync IS 'Plorix: uma linha (id=1) com todos os dados da equipa';

INSERT INTO public.plorix_sync (id, payload)
VALUES (1, '{"users": [{"username": "admin", "name": "Administrador", "roles": ["admin", "dona"], "passHash": "8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918", "permissions": {"qualidadeEmbarque": true, "avaria": true}}]}'::jsonb)
ON CONFLICT (id) DO NOTHING;

ALTER TABLE public.plorix_sync ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "plorix_sync_select" ON public.plorix_sync;
DROP POLICY IF EXISTS "plorix_sync_insert" ON public.plorix_sync;
DROP POLICY IF EXISTS "plorix_sync_update" ON public.plorix_sync;
DROP POLICY IF EXISTS "plorix_sync_delete" ON public.plorix_sync;

CREATE POLICY "plorix_sync_select"
  ON public.plorix_sync
  FOR SELECT
  TO anon, authenticated
  USING (
    id != 1 OR
    current_setting('request.headers', true)::json->>'x-plorix-hash' = '8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918'
  );

CREATE POLICY "plorix_sync_insert"
  ON public.plorix_sync
  FOR INSERT
  TO anon, authenticated
  WITH CHECK (
    id != 1 OR
    current_setting('request.headers', true)::json->>'x-plorix-hash' = '8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918'
  );

CREATE POLICY "plorix_sync_update"
  ON public.plorix_sync
  FOR UPDATE
  TO anon, authenticated
  USING (
    id != 1 OR
    current_setting('request.headers', true)::json->>'x-plorix-hash' = '8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918'
  )
  WITH CHECK (
    id != 1 OR
    current_setting('request.headers', true)::json->>'x-plorix-hash' = '8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918'
  );

CREATE POLICY "plorix_sync_delete"
  ON public.plorix_sync
  FOR DELETE
  TO anon, authenticated
  USING (
    id != 1 OR
    current_setting('request.headers', true)::json->>'x-plorix-hash' = '8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918'
  );

GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.plorix_sync TO anon, authenticated;

-- ############## BLOCO C — Teste (tem de devolver 1 linha) ##############
SELECT
  id,
  updated_at,
  jsonb_typeof(payload) AS tipo_do_payload,
  'OK — Plorix pode sincronizar' AS status
FROM public.plorix_sync
WHERE id = 1;
