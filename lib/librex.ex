defmodule Librex do
  @moduledoc """
  Provides functions to convert office documents to other formats.

   ## Examples
      iex(1)> Librex.convert("test/fixtures/docx.docx", "/Users/ricn/docx.pdf")
      {:ok, "/Users/ricn/docx.pdf"}

      iex(2)> Librex.convert("non_existent_file", "/Users/ricn/docx.pdf")
      {:error, :enoent}

      iex(3)> Librex.convert!("test/fixtures/docx.docx", "/Users/ricn/docx.pdf")
      "/Users/ricn/docx.pdf"

      iex(4)> Librex.convert!("non_existent_file", "/Users/ricn/docx.pdf")
      ** (File.Error) could not read non_existent_file: no such file or directory
      (librex) lib/librex.ex:13: Librex.convert!/3
   """

  @doc """
    Converts in_file to out_file
    Returns `:ok` if successful, `{:error, reason}` otherwise.
  """
  def convert(in_file, out_file, soffice_cmd \\ "soffice") do
    case File.read(in_file) do
      {:ok, _}  -> do_convert(in_file, out_file, soffice_cmd)
      {:error, reason } -> {:error, reason}
    end
  end

  @doc """
    The same as `convert/3`, but raises an exception if it fails.
  """
  def convert!(in_file, out_file, soffice_cmd \\ "soffice") do
    case convert(in_file, out_file, soffice_cmd) do
      {:ok, _}      -> out_file
      {:error, reason} -> raise File.Error, reason: reason, action: "read", path: in_file
    end
  end

  defp do_convert(in_file, out_file, soffice_cmd) do
    basename = Path.basename(in_file, Path.extname(in_file))
    convert_to = String.replace(Path.extname(out_file), ".", "")
    out_temp_dir = System.tmp_dir! <> "/" <> SecureRandom.uuid <> "/"
    out_temp_file = out_temp_dir <> basename <> Path.extname(out_file)

    run(in_file, out_temp_dir, convert_to, soffice_cmd)

    File.cp! out_temp_file, out_file
    File.rm! out_temp_file
    File.rmdir! out_temp_dir

    {:ok, out_file}
  end

  defp run(file_to_convert, out_dir, convert_to, soffice_cmd) do
    opts = ["--headless", "--convert-to", convert_to, "--outdir", out_dir, file_to_convert]
    cmd = System.find_executable(soffice_cmd)
    case cmd do
      nil -> raise RuntimeError, message: "LibreOffice (#{soffice_cmd}) executable could not be found."
      _ -> System.cmd(cmd, opts, stderr_to_stdout: true)
    end
  end
end
