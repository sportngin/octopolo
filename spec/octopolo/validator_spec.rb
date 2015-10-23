module Octopolo
  describe Validator do
    let(:cli) { stub(:CLI) }
    let(:config) { stub(:Config) }

    subject { Validator.new }

    before do
      subject.config = config
      subject.cli = cli
    end

    describe '#is_valid?' do
      it 'should be valid with no validations' do
        allow(cli).to receive(:say)
        subject.validations = nil
        expect(subject.is_valid?).to be_true
        subject.validations = []
        expect(subject.is_valid?).to be_true
      end

      it 'should be valid' do
        allow(cli).to receive(:say)
        subject.validations = ['exit 0']
        expect(cli).to receive(:perform)
        expect(subject.is_valid?).to be_true
      end

      it 'should be invalid' do
        allow(cli).to receive(:say)
        subject.validations = ['exit 1']
        expect(cli).to receive(:perform).and_raise('boom')
        expect{subject.is_valid?}.to raise_error
      end
    end

    describe '#validate' do
      it 'should be valid with no validations' do
        allow(cli).to receive(:say)
        subject.validations = []
        expect(subject.validate).to be_true
      end

      it 'should be valid' do
        subject.validations = ['exit 0']
        expect(cli).to receive(:perform)
        expect(subject.validate).to be_true
      end

      it 'should be invalid' do
        allow(cli).to receive(:say)
        subject.validations = ['exit 1']
        expect(cli).to receive(:perform).and_raise('boom')
        expect{subject.validate}.to raise_error
      end
    end

  end
end
