-- Handy: добавляет недостающее правило удаления заданий
-- Выполнить в Supabase Dashboard → SQL Editor → New query → Run

create policy "clients can delete their own tasks"
  on tasks for delete
  to authenticated
  using (auth.uid() = client_id);
