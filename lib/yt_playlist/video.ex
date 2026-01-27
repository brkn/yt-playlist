defmodule YtPlaylist.Video do
  @moduledoc """
  YouTube video struct with Ecto schema for SQLite persistence.

  Uses yt-dlp field names throughout.
  """

  # NOTE: Idk why we need playlist_name as a column at every record.
  # Since we have a single db per playlist, all of them would have the same value?
  #

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :id, autogenerate: true}
  schema "videos" do
    field(:playlist_name, :string)
    field(:title, :string)
    field(:channel, :string)
    field(:uploader, :string)
    field(:duration, :integer)
    field(:duration_string, :string)
    field(:webpage_url, :string)
    field(:view_count, :integer)
    field(:like_count, :integer)
    field(:channel_follower_count, :integer)
    field(:channel_is_verified, :boolean)
    field(:description, :string)
    field(:categories, :string)
    field(:tags, :string)
    field(:upload_date, :string)
    field(:availability, :string)

    timestamps(type: :utc_datetime, updated_at: false, inserted_at: :created_at)
  end

  @fields [
    :playlist_name,
    :title,
    :channel,
    :uploader,
    :duration,
    :duration_string,
    :webpage_url,
    :view_count,
    :like_count,
    :channel_follower_count,
    :channel_is_verified,
    :description,
    :categories,
    :tags,
    :upload_date,
    :availability
  ]

  @doc """
  Converts a yt-dlp JSON map to a Video struct.

  Only extracts fields defined in the schema, ignoring extra keys.
  Missing fields default to nil.
  """
  def from_json(map) when is_map(map) do
    map
    |> atomize_keys()
    |> then(&struct(__MODULE__, &1))
  end

  @doc """
  Creates a changeset for inserting a video into the database.
  """
  def changeset(%__MODULE__{} = video, attrs \\ %{}) do
    video
    |> cast(attrs, @fields)
    |> validate_required([:playlist_name, :title, :webpage_url])
    |> unique_constraint(:webpage_url)
  end

  @doc """
  Creates a changeset from a Video struct for database insertion.
  """
  def to_changeset(%__MODULE__{} = video, playlist_name) do
    video
    |> Map.from_struct()
    |> Map.put(:playlist_name, playlist_name)
    |> update_if_list(:categories)
    |> update_if_list(:tags)
    |> then(&changeset(%__MODULE__{}, &1))
  end

  # struct/2 expects atom keys, Jason.decode! returns string keys
  defp atomize_keys(map) do
    Map.new(map, fn {k, v} -> {String.to_atom(k), v} end)
  end

  # Encode lists as JSON strings for SQLite TEXT columns
  defp update_if_list(map, key) do
    case Map.get(map, key) do
      list when is_list(list) -> Map.put(map, key, Jason.encode!(list))
      _ -> map
    end
  end
end
