class Bib < ActiveRecord::Base
  include HasRecordProperty
  include OutputPdf

  LABEL_HEADER = ["Id", "Name", "Authors"]

  has_many :bib_authors
  has_many :authors, through: :bib_authors

  has_many :attachings, as: :attachable
  has_many :attachment_files, through: :attachings
  has_many :referrings
  has_many :stones, through: :referrings, source: :referable, source_type: "Stone"
  has_many :places, through: :referrings, source: :referable, source_type: "Place"
  has_many :boxes, through: :referrings, source: :referable, source_type: "Box"
  has_many :analyses, through: :referrings, source: :referable, source_type: "Analysis"
  
  def doi_link_url
    return unless doi
    "http://dx.doi.org/#{doi}"
  end
  
  def primary_pdf_attachment_file
    pdf_files.first if pdf_files.present?
  end

  def build_label
    CSV.generate do |csv|
      csv << LABEL_HEADER
      csv << ["#{global_id}", "#{name}", "#{author_lists}"]
    end
  end

  def self.build_bundle_label(bibs)
    CSV.generate do |csv|
      csv << LABEL_HEADER
      bibs.each do |bib|
        csv << ["#{bib.global_id}", "#{bib.name}", "#{bib.author_lists}"]
      end
    end
  end

  def author_lists
    authors.pluck(:name).join(" ")
  end

  private

  def pdf_files
    if attachment_files.present?
      attachment_files.order("updated_at desc").select {|file| file.pdf? }
    end
  end
end
