import unittest
from types import SimpleNamespace
from unittest import mock

import pandas as pd
from sqlalchemy.exc import OperationalError

import pipeline


def _llm_reply(text):
    return SimpleNamespace(choices=[SimpleNamespace(message=SimpleNamespace(content=text))])


class ValidateSqlTests(unittest.TestCase):
    def test_accepts_select_and_with(self):
        self.assertEqual(pipeline.validate_sql("SELECT 1;"), "SELECT 1")
        pipeline.validate_sql("WITH a AS (SELECT 1) SELECT * FROM a")

    def test_accepts_column_names_containing_keywords(self):
        pipeline.validate_sql("SELECT created_at, updated_by FROM orders")

    def test_rejects_multiple_statements(self):
        with self.assertRaises(ValueError):
            pipeline.validate_sql("SELECT 1; DROP TABLE orders")

    def test_rejects_non_select(self):
        with self.assertRaises(ValueError):
            pipeline.validate_sql("DELETE FROM orders")

    def test_rejects_writes_hidden_in_cte(self):
        with self.assertRaises(ValueError):
            pipeline.validate_sql("WITH x AS (DELETE FROM orders RETURNING *) SELECT * FROM x")

    def test_rejects_pg_sleep(self):
        with self.assertRaises(ValueError):
            pipeline.validate_sql("SELECT pg_sleep(100)")

    def test_rejects_empty(self):
        with self.assertRaises(ValueError):
            pipeline.validate_sql("  ;  ")


class AskTests(unittest.TestCase):
    def setUp(self):
        pipeline.conversation_history.clear()

    def test_refusal_returns_empty_and_not_stored(self):
        with mock.patch.object(pipeline, "_generate_sql", return_value=pipeline.REFUSAL_TOKEN):
            df = pipeline.ask("what is the capital of France?")
        self.assertTrue(df.empty)
        self.assertEqual(pipeline.conversation_history, [])

    def test_retries_on_db_error_then_stores_only_success(self):
        err = OperationalError("stmt", {}, Exception("column foo does not exist"))
        gen = mock.Mock(side_effect=["SELECT foo FROM orders", "SELECT 1 AS n"])
        run = mock.Mock(side_effect=[err, pd.DataFrame({"n": [1]})])
        with mock.patch.object(pipeline, "_generate_sql", gen), \
             mock.patch.object(pipeline, "_run_readonly", run), \
             mock.patch.object(pipeline, "_decide_visualization", return_value={"visualize": False}):
            df = pipeline.ask("q")
        self.assertEqual(len(df), 1)
        self.assertEqual(gen.call_count, 2)
        self.assertIn("column foo does not exist", gen.call_args[0][0][-1]["content"])
        self.assertEqual(len(pipeline.conversation_history), 2)

    def test_unsafe_sql_raises_and_not_stored(self):
        with mock.patch.object(pipeline, "_generate_sql", return_value="DROP TABLE orders"):
            with self.assertRaises(ValueError):
                pipeline.ask("q")
        self.assertEqual(pipeline.conversation_history, [])

    def test_history_is_capped(self):
        with mock.patch.object(pipeline, "_generate_sql", return_value="SELECT 1"), \
             mock.patch.object(pipeline, "_run_readonly", return_value=pd.DataFrame({"n": [1]})), \
             mock.patch.object(pipeline, "_decide_visualization", return_value={"visualize": False}):
            for _ in range(pipeline.MAX_HISTORY_MESSAGES):
                pipeline.ask("q")
        self.assertEqual(len(pipeline.conversation_history), pipeline.MAX_HISTORY_MESSAGES)

    def test_empty_model_content_raises_clear_error(self):
        client = mock.Mock()
        client.chat.completions.create.return_value = _llm_reply(None)
        with mock.patch.object(pipeline, "_get_groq_client", return_value=client):
            with self.assertRaises(RuntimeError):
                pipeline._generate_sql([{"role": "user", "content": "q"}])


if __name__ == "__main__":
    unittest.main()
