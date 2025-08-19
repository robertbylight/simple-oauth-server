require 'rails_helper'

RSpec.describe PkceValidator do
  describe '.validate' do
    let(:code_verifier) { 'msibjqawCU_Xz0RNU-uHQq3QKG_Ir_Zw5HBLZmQn8v8' }
    let(:code_challenge) { '6BOLKGAIt7da4roth_pXMrRdUh9QHe-hqtVSwjU6cps' }

    context 'when code_verifier matches code_challenge' do
      it 'returns true' do
        result = described_class.validate(code_challenge, code_verifier)
        expect(result).to be true
      end
    end

    context 'when code_verifier does not match code_challenge' do
      it 'returns false' do
        wrong_verifier = 'wrong'
        result = described_class.validate(code_challenge, wrong_verifier)
        expect(result).to be false
      end
    end

    context 'when code_challenge is blank' do
      it 'returns false for nil' do
        result = described_class.validate(nil, code_verifier)
        expect(result).to be false
      end

      it 'returns false for empty string' do
        result = described_class.validate('', code_verifier)
        expect(result).to be false
      end
    end

    context 'when code_verifier is blank' do
      it 'returns false for nil' do
        result = described_class.validate(code_challenge, nil)
        expect(result).to be false
      end

      it 'returns false for empty string' do
        result = described_class.validate(code_challenge, '')
        expect(result).to be false
      end
    end

    context 'when both parameters are blank' do
      it 'returns false' do
        result = described_class.validate(nil, nil)
        expect(result).to be false
      end
    end
  end
end
