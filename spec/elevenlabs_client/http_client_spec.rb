# frozen_string_literal: true

RSpec.describe ElevenlabsClient::HttpClient do
  let(:api_key) { "test_api_key" }
  let(:http_client) { described_class.new(api_key: api_key) }

  describe "#mime_for" do
    # Test private method using send
    let(:mime_for) { ->(filename) { http_client.send(:mime_for, filename) } }

    context "video file types" do
      it "returns correct MIME type for MP4 files" do
        expect(mime_for.call("video.mp4")).to eq("video/mp4")
        expect(mime_for.call("VIDEO.MP4")).to eq("video/mp4") # case insensitive
      end

      it "returns correct MIME type for MOV files" do
        expect(mime_for.call("video.mov")).to eq("video/quicktime")
      end

      it "returns correct MIME type for AVI files" do
        expect(mime_for.call("video.avi")).to eq("video/x-msvideo")
      end

      it "returns correct MIME type for MKV files" do
        expect(mime_for.call("video.mkv")).to eq("video/x-matroska")
      end
    end

    context "audio file types" do
      it "returns correct MIME type for MP3 files" do
        expect(mime_for.call("audio.mp3")).to eq("audio/mpeg")
      end

      it "returns correct MIME type for WAV files" do
        expect(mime_for.call("audio.wav")).to eq("audio/wav")
      end

      it "returns correct MIME type for FLAC files" do
        expect(mime_for.call("audio.flac")).to eq("audio/flac")
      end

      it "returns correct MIME type for M4A files" do
        expect(mime_for.call("audio.m4a")).to eq("audio/mp4")
      end
    end

    context "document file types" do
      it "returns correct MIME type for PDF files" do
        expect(mime_for.call("document.pdf")).to eq("application/pdf")
        expect(mime_for.call("DOCUMENT.PDF")).to eq("application/pdf") # case insensitive
      end

      it "returns correct MIME type for EPUB files" do
        expect(mime_for.call("book.epub")).to eq("application/epub+zip")
      end

      it "returns correct MIME type for DOCX files" do
        expect(mime_for.call("document.docx")).to eq("application/vnd.openxmlformats-officedocument.wordprocessingml.document")
      end

      it "returns correct MIME type for DOC files" do
        expect(mime_for.call("document.doc")).to eq("application/msword")
      end

      it "returns correct MIME type for TXT files" do
        expect(mime_for.call("text.txt")).to eq("text/plain")
      end

      it "returns correct MIME type for HTML files" do
        expect(mime_for.call("page.html")).to eq("text/html")
        expect(mime_for.call("page.htm")).to eq("text/html")
      end

      it "returns correct MIME type for Markdown files" do
        expect(mime_for.call("readme.md")).to eq("text/markdown")
      end
    end

    context "unknown file types" do
      it "returns default MIME type for unknown extensions" do
        expect(mime_for.call("file.unknown")).to eq("application/octet-stream")
        expect(mime_for.call("file.xyz")).to eq("application/octet-stream")
      end

      it "returns default MIME type for files without extensions" do
        expect(mime_for.call("file")).to eq("application/octet-stream")
      end
    end

    context "edge cases" do
      it "handles filenames with multiple dots" do
        expect(mime_for.call("my.document.pdf")).to eq("application/pdf")
        expect(mime_for.call("archive.tar.gz")).to eq("application/octet-stream")
      end

      it "handles filenames with paths" do
        expect(mime_for.call("/path/to/document.pdf")).to eq("application/pdf")
        expect(mime_for.call("path/to/document.pdf")).to eq("application/pdf")
      end

      it "handles empty filenames" do
        expect(mime_for.call("")).to eq("application/octet-stream")
      end
    end
  end

  describe "#file_part" do
    let(:file_io) { StringIO.new("test content") }

    it "creates a FilePart with correct MIME type for PDF" do
      file_part = http_client.file_part(file_io, "document.pdf")
      expect(file_part).to be_a(Faraday::Multipart::FilePart)
      expect(file_part.content_type).to eq("application/pdf")
    end

    it "creates a FilePart with correct MIME type for EPUB" do
      file_part = http_client.file_part(file_io, "book.epub")
      expect(file_part).to be_a(Faraday::Multipart::FilePart)
      expect(file_part.content_type).to eq("application/epub+zip")
    end

    it "creates a FilePart with correct MIME type for DOCX" do
      file_part = http_client.file_part(file_io, "document.docx")
      expect(file_part).to be_a(Faraday::Multipart::FilePart)
      expect(file_part.content_type).to eq("application/vnd.openxmlformats-officedocument.wordprocessingml.document")
    end

    it "creates a FilePart with correct MIME type for DOC" do
      file_part = http_client.file_part(file_io, "document.doc")
      expect(file_part).to be_a(Faraday::Multipart::FilePart)
      expect(file_part.content_type).to eq("application/msword")
    end

    it "creates a FilePart with correct MIME type for TXT" do
      file_part = http_client.file_part(file_io, "text.txt")
      expect(file_part).to be_a(Faraday::Multipart::FilePart)
      expect(file_part.content_type).to eq("text/plain")
    end

    it "creates a FilePart with correct MIME type for HTML" do
      file_part = http_client.file_part(file_io, "page.html")
      expect(file_part).to be_a(Faraday::Multipart::FilePart)
      expect(file_part.content_type).to eq("text/html")
    end

    it "creates a FilePart with correct MIME type for HTM" do
      file_part = http_client.file_part(file_io, "page.htm")
      expect(file_part).to be_a(Faraday::Multipart::FilePart)
      expect(file_part.content_type).to eq("text/html")
    end

    it "creates a FilePart with correct MIME type for Markdown" do
      file_part = http_client.file_part(file_io, "readme.md")
      expect(file_part).to be_a(Faraday::Multipart::FilePart)
      expect(file_part.content_type).to eq("text/markdown")
    end

    it "creates a FilePart with default MIME type for unknown extensions" do
      file_part = http_client.file_part(file_io, "file.unknown")
      expect(file_part).to be_a(Faraday::Multipart::FilePart)
      expect(file_part.content_type).to eq("application/octet-stream")
    end
  end
end

