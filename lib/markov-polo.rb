module MarkovPolo
  VERSION = "0.1.1"

  class Chain
    START_TOKEN = "__start__"
    END_TOKEN = "__end__"

    def initialize hash={}
      @data = hash
    end

    def data
      @data
    end

    def << content; push content; end
    def >> content; reverse_push content; end

    def push content
      last = START_TOKEN
      content.split.each do |word|
        add_member last, word
        last = word
      end
      add_member last, END_TOKEN
    end

    def reverse_push content
      last = START_TOKEN
      content.split.reverse_each do |word|
        add_member last, word
        last = word
      end
      add_member last, END_TOKEN
    end

    def add_member last, word
      @data[last] = {} unless @data.include? last
      @data[last][word] = 0 unless @data[last].include? word
      @data[last][word] += 1
    end

    def to_h; @data; end
    def to_hash; to_h; end
    def load hash; @data = hash; end

    def markov(start = nil)
      generate(start).join " "
    end

    def remarkov(start = nil)
      generate(start).reverse.join " "
    end

    def generate(start)
      return [start] unless start.nil? || @data.has_key?(start)
      last = start || START_TOKEN
      total = [start].compact
      while last != END_TOKEN
        choices = []
        @data[last].each do |key, val|
          val.times { choices << key }
        end
        chosen = choices.sample

        total << chosen unless chosen == END_TOKEN
        last = chosen
      end
      total
    end

    private :add_member, :generate
  end
end