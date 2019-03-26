defmodule GitGud.DB.Migrations.AddCommitLineReviewsTable do
  use Ecto.Migration

  def change do
    create table("commit_line_reviews") do
      add :repo_id, references("repositories"), null: false, on_delete: :delete_all
      add :oid, :binary, null: false
      add :blob_oid, :binary, null: false
      add :hunk, :integer, null: false
      add :line, :integer, null: false
      timestamps()
    end

    create unique_index("commit_line_reviews", [:repo_id, :oid, :blob_oid, :hunk, :line])

    create table("commit_line_reviews_comments", primary_key: false) do
      add :review_id, references("commit_line_reviews"), null: false, on_delete: :delete_all
      add :comment_id, references("comments"), null: false, on_delete: :delete_all
    end
  end
end