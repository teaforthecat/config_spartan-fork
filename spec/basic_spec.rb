require 'spec_helper'

describe ConfigSpartan do
  context '.create' do
    before do
      @config = ConfigSpartan.create { file('spec/config1.yml') }
    end
    it 'reads yaml' do
      expect(@config.host).to eql('dev.something.com')
      expect(@config.urls).to eql(%w[www.google.com www.yahoo.com])
      expect(@config[:count]).to eql(11)
    end

    it 'raises NoMethodError when config is not set' do
      expect { @config.nothing }.to raise_error(NoMethodError)
      expect { @config.nest.nothing }.to raise_error(NoMethodError)
    end

    it 'does not raise error when a value is set to nil' do
      expect { @config.really_nothing }.not_to raise_error
      expect(@config.really_nothing).to eql(nil)
    end

    context 'files' do
      it 'merges multiple files' do
        config = ConfigSpartan.create do
          file 'spec/config1.yml'
          file 'spec/config2.yml'
        end

        expect(config.host).to eq('prod.something.com')
        expect(config.urls).to eq(%w[www.bing.com www.cuil.com])
        expect(config[:count]).to eq(11)
        expect(config.nest.something).to eq('blah')
        expect(config.nest.name.fname).to eq('coco')
        expect(config.nest.name.lname).to eq('bottaro')
      end
    end

    context 'merging' do
      config = ConfigSpartan.create do
        file 'spec/config2.yml'
        file 'spec/config3.yml'
      end

      it 'does not merge arrays' do
        expect(config.urls).to eq(%w[www.yandex.com]) # no "www.bing.com"
        expect(config.nest.other_urls).to eq(%w[c]) # does not have a,b
      end

      it 'does merge hashes' do
        expect(config.nest.name.mname).to eq('mega') # from config3
        expect(config.nest.name.fname).to eq('coco') # from config2
      end
    end
  end

  context '.require' do
    before do
      @config = ConfigSpartan.create { file('spec/config1.yml') }
    end
    it 'requires takes both symbols and strings' do
      result = { 'there' => 'maybe', 'else' => { 'nested' => true } }
      expect(@config.something.require(:there, 'else')).to eq(result)
      # retaining dot access
      expect(@config.something.require(:there).there).to eq('maybe')
    end
    it 'blows up if key not present' do
      something = @config.something
      expect { something.require(:missing) }.to raise_error(NoMethodError)
    end
  end

  context '.permit' do
    before do
      @config = ConfigSpartan.create { file('spec/config1.yml') }
    end
    it 'presence is ok' do
      expect(@config.something.permit(:there).there).to eq('maybe')
    end
    it 'absence is ok' do
      expect(@config.something.permit(:absent,:there).there).to eq('maybe')
      expect(@config.something.permit(:absent).there).to eq('maybe')
    end
  end
end
