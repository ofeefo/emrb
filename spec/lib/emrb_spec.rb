# frozen_string_literal: true

RSpec.describe Emrb do
  around do |example|
    reset_registry!
    example.call
    reset_registry!
  end

  let(:raw_dummy) { Class.new.tap { _1.include(Emrb::Instruments) } }

  it "does not allow instruments to be redeclared with names that collide with class methods" do
    Emrb::Instruments::ClassMethods::FORBIDDEN_IDENTIFIERS.each do |id|
      expect { raw_dummy.counter id }.to raise_error Emrb::Instruments::CollidingNameError
    end
  end

  it "works with simple delcarations" do
    raw_dummy.counter :counter1, "a counter", labels: [:label], preset_labels: { label: "label" }
    presets = raw_dummy.counter1.preset_labels
    expect(presets.length).to eq 1
    expect(presets[:label]).to eq "label"
  end

  it "works with block declarations" do
    raw_dummy.counter :counter1, "a counter" do
      { labels: [:label], preset_labels: { label: "label" } }
    end

    presets = raw_dummy.counter1.preset_labels
    expect(presets.length).to eq 1
    expect(presets[:label]).to eq "label"
  end

  context "basic usage" do
    let(:dummy) do
      Class.new(raw_dummy).tap do |c|
        c.gauge :gauge1, "base gauge"
        c.counter :counter1, "base counter"
        c.summary :summary1, "base summary"
        c.histogram :histogram1, "base_histogram"
      end
    end

    let(:dummy2) do
      Class.new(dummy)
    end

    it "performs all measurements as expected with default methods" do
      expect do
        dummy.gauge1.increment
        dummy.counter1.increment
        dummy.histogram1.observe(1.0)
        dummy.summary1.observe(1.0)
      end.to_not raise_error

      [dummy.counter1, dummy.gauge1].each do |i|
        expect(i.get).to eq 1
      end

      [dummy.histogram1, dummy.summary1].each do |i|
        expect(i.get["sum"]).to eq 1
      end
    end

    it "works with inheritance" do
      expect do
        dummy2.counter1.inc
        dummy2.gauge1.inc
        dummy2.histogram1.obs(1.0)
        dummy2.summary1.obs(1.0)
      end.to_not raise_error

      [dummy2.counter1, dummy2.gauge1].each do |i|
        expect(i.get).to eq 1
      end

      [dummy2.histogram1, dummy2.summary1].each do |i|
        expect(i.get["sum"]).to eq 1
      end
    end
  end

  context "with presets" do
    let(:dummy) do
      Class.new(raw_dummy).tap do |c|
        c.with_presets label: "label" do
          counter :counter1, "a_counter"
        end
        c.counter :counter2, "b_counter"
      end
    end

    it "leverages presets only for instruments within the block" do
      c1 = dummy.counter1
      expect(c1.labels.length).to eq 1
      expect(c1.preset_labels[:label]).to eq "label"

      c2 = dummy.counter2
      expect(c2.labels.length).to eq 0
    end
  end

  context "with subsystem" do
    let(:dummy) do
      Class.new(raw_dummy).tap do |c|
        c.subsystem :subsys, some: "label" do
          counter :sub_counter, "sub_counter"
        end
      end
    end

    it "does not respond to subsystem methods directely" do
      expect { Sub.sub_counter }.to raise_error NameError
    end

    it "works as expected" do
      sc = nil
      expect { sc = dummy.subsys.sub_counter }.to_not raise_error
      expect(sc.name).to eq(:subsys_sub_counter)
      expect(sc.labels.length).to eq 1
      expect(sc.preset_labels.length).to eq 1
      expect(sc.preset_labels[:some]).to eq "label"
    end
  end

  context "with nested subsystems" do
    it "does not inherits parent presets" do
      dummy = Class.new(raw_dummy).tap do |d|
        d.subsystem :outer, some: "label" do
          subsystem :inner do
            counter :counter1, "inner_counter"
          end
        end
      end

      ic = nil
      expect { ic = dummy.outer.inner.counter1 }.to_not raise_error
      expect(ic.name).to eq :outer_inner_counter1
      expect(ic.labels.length).to eq 0
    end

    it "inherits parent presets" do
      dummy = Class.new(raw_dummy).tap do |d|
        d.subsystem :outer, some: "label" do
          subsystem :inner, inherit_presets: true, other: "label_2" do
            counter :counter1, "inner_counter"
          end
        end
      end

      ic = nil
      expect { ic = dummy.outer.inner.counter1 }.to_not raise_error
      expect(ic.name).to eq :outer_inner_counter1
      expect(ic.preset_labels.length).to eq 2
      expect(ic.preset_labels[:some]).to eq "label"
      expect(ic.preset_labels[:other]).to eq "label_2"
    end

    it "works using presets inside the subsystem" do
      dummy = Class.new(raw_dummy).tap do |d|
        d.with_presets some: "label" do
          subsystem :outer, inherit_presets: true do
            subsystem :inner, inherit_presets: true do
              with_presets other: "label2" do
                counter :counter1, "inner_counter" do
                  { labels: [:more], preset_labels: { more: "label3" } }
                end
              end
            end
          end
        end
      end

      ic = nil
      expect { ic = dummy.outer.inner.counter1 }.to_not raise_error
      expect(ic.preset_labels.length).to eq 3
      expect(ic.preset_labels[:some]).to eq "label"
      expect(ic.preset_labels[:other]).to eq "label2"
      expect(ic.preset_labels[:more]).to eq "label3"
    end
  end
end
