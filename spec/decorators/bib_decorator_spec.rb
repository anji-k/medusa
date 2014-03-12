require 'spec_helper'

describe BibDecorator do
  let(:user) { FactoryGirl.create(:user) }
  before{ User.current = user }
  
  describe ".name_with_id" do
  end
  
  describe ".to_tex" do
    subject { bib.to_tex }
    let(:bib) { FactoryGirl.create(:bib, entry_type: entry_type, abbreviation: abbreviation).decorate }
    describe "@article" do
      before do
        bib
        allow(bib).to receive(:article_tex).and_return("test")
      end
      let(:entry_type) { "article" }
      context "abbreviation is not nil" do
        let(:abbreviation) { "abbreviation" }
        it { expect(subject).to eq "\n@article{abbreviation,\ntest,\n}" }
      end
      context "abbreviation is nil" do
        let(:abbreviation) { "" }
        it { expect(subject).to eq "\n@article{#{bib.global_id},\ntest,\n}" }
      end
    end
    describe "@misc" do
      before do
        bib
        allow(bib).to receive(:misc_tex).and_return("test")
      end
      let(:entry_type) { "entry_type" }
      context "abbreviation is not nil" do
        let(:abbreviation) { "abbreviation" }
        it { expect(subject).to eq "\n@misc{abbreviation,\ntest,\n}" }
      end
      context "abbreviation is nil" do
        let(:abbreviation) { "" }
        it { expect(subject).to eq "\n@misc{#{bib.global_id},\ntest,\n}" }
      end
    end
  end
  
  describe ".article_tex" do
    subject { bib.article_tex }
    before do
      bib
      allow(bib).to receive(:bib_author_lists).and_return(author.name)
    end
    let(:bib) do
      FactoryGirl.create(:bib,
        number: number,
        month: month,
        volume: volume,
        pages: pages,
        note: note,
        doi: doi,
        key: key
      ).decorate
    end
    let(:author) { FactoryGirl.create(:author) }
    context "value is nil" do
      let(:number) { "" }
      let(:month) { "" }
      let(:volume) { "" }
      let(:pages) { "" }
      let(:note) { "" }
      let(:doi) { "" }
      let(:key) { "" }
      it { expect(subject).to eq "\tauthor = \"著者１\",\n\tname = \"書誌情報１\",\n\tjournal = \"雑誌名１\",\n\tyear = \"2014\"" }
    end
    context "value is not nil" do
      let(:number) { "1" }
      let(:month) { "month" }
      let(:volume) { "1" }
      let(:pages) { "1" }
      let(:note) { "note" }
      let(:doi) { "doi" }
      let(:key) { "key" }
      it { expect(subject).to eq "\tauthor = \"著者１\",\n\tname = \"書誌情報１\",\n\tjournal = \"雑誌名１\",\n\tyear = \"2014\",\n\tnumber = \"1\",\n\tmonth = \"month\",\n\tvolume = \"1\",\n\tpages = \"1\",\n\tnote = \"note\",\n\tdoi = \"doi\",\n\tkey = \"key\"" }
    end
  end
  
  describe ".misc_tex" do
    subject { bib.misc_tex }
    before do
      bib
      allow(bib).to receive(:bib_author_lists).and_return(author.name)
    end
    let(:bib) do
      FactoryGirl.create(:bib,
        number: number,
        month: month,
        journal: journal,
        volume: volume,
        pages: pages,
        year: year,
        note: note,
        doi: doi,
        key: key
      ).decorate
    end
    let(:author) { FactoryGirl.create(:author) }
    context "value is nil" do
      let(:number) { "" }
      let(:month) { "" }
      let(:journal) { "" }
      let(:volume) { "" }
      let(:pages) { "" }
      let(:year) { "" }
      let(:note) { "" }
      let(:doi) { "" }
      let(:key) { "" }
      it { expect(subject).to eq "\tauthor = \"著者１\",\n\tname = \"書誌情報１\"" }
    end
    context "value is not nil" do
      let(:number) { "1" }
      let(:month) { "month" }
      let(:journal) { "journal" }
      let(:volume) { "1" }
      let(:pages) { "1" }
      let(:year) { "2014" }
      let(:note) { "note" }
      let(:doi) { "doi" }
      let(:key) { "key" }
      it { expect(subject).to eq "\tauthor = \"著者１\",\n\tname = \"書誌情報１\",\n\tnumber = \"1\",\n\tmonth = \"month\",\n\tjournal = \"journal\",\n\tvolume = \"1\",\n\tpages = \"1\",\n\tyear = \"2014\",\n\tnote = \"note\",\n\tdoi = \"doi\",\n\tkey = \"key\"" }
    end
  end
  
  describe ".bib_author_lists" do
    subject { bib.bib_author_lists }
    before do
      bib
      allow(bib.authors).to receive(:pluck).with(:name).and_return([author.name])
    end
    let(:bib) { FactoryGirl.create(:bib).decorate }
    let(:author) { FactoryGirl.create(:author) }
    it { expect(subject).to eq "著者１" }
  end
  
end