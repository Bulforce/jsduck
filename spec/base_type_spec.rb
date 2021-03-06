require "jsduck/base_type"
require "jsduck/doc/map"
require "jsduck/js/ast"
require "jsduck/js/parser"
require "jsduck/css/parser"
require "jsduck/doc/parser"

describe JsDuck::BaseType do
  def detect(string, type = :js)
    if type == :css
      node = JsDuck::Css::Parser.new(string).parse[0]
    else
      node = JsDuck::Js::Parser.new(string).parse[0]
      node[:code] = JsDuck::Js::Ast.new.detect(node[:code])
    end

    doc_parser = JsDuck::Doc::Parser.new
    node[:comment] = doc_parser.parse(node[:comment])
    node[:doc_map] = JsDuck::Doc::Map.build(node[:comment])
    return JsDuck::BaseType.detect(node[:doc_map], node[:code])
  end

  describe "detects as class" do
    it "@class tag" do
      detect("/** @class */").should == :class
    end

    it "class-like function" do
      detect("/** */ function MyClass() {}").should == :class
    end

    it "Ext.define()" do
      detect(<<-EOS).should == :class
        /** */
        Ext.define('MyClass', {
        });
      EOS
    end
  end

  describe "detects as method" do
    it "@method tag" do
      detect("/** @method */").should == :method
    end

    it "@constructor tag" do
      detect("/** @constructor */").should == :method
    end

    it "@param tag" do
      detect("/** @param {Number} x */").should == :method
    end

    it "@return tag" do
      detect("/** @return {Boolean} */").should == :method
    end

    it "function declaration" do
      detect("/** */ function foo() {}").should == :method
    end
  end

  describe "detects as event" do
    it "@event tag" do
      detect("/** @event */").should == :event
    end

    it "@event and @param tags" do
      detect("/** @event @param {Number} x */").should == :event
    end
  end

  describe "detects as config" do
    it "@cfg tag" do
      detect("/** @cfg */").should == :cfg
    end
  end

  describe "detects as property" do
    it "@property tag" do
      detect("/** @property */").should == :property
    end

    it "@type tag" do
      detect("/** @type Foo */").should == :property
    end

    it "empty doc-comment with no code" do
      detect("/** */").should == :property
    end
  end

  describe "detects as css variable" do
    it "@var tag" do
      detect("/** @var */").should == :css_var
    end
  end

  describe "detects as css mixin" do
    it "@mixin in code" do
      detect("/** */ @mixin foo-bar {}", :css).should == :css_mixin
    end

    it "@param in doc and @mixin in code" do
      detect("/** @param {number} $foo */ @mixin foo-bar {}", :css).should == :css_mixin
    end
  end

end
