#!/usr/bin/env ruby

require 'stringio'
require 'yaml'
require 'bundler'
Bundler.require

r = RSRuby.instance

r.eval_R("suppressMessages(library('tm.plugin.webmining'))")
r.eval_R("suppressMessages(library('tm.plugin.sentiment'))")

web_corpus = r.eval_R("corpus <- WebCorpus(GoogleNewsSource('#{ARGV[0]}'))")
r.eval_R('corpus <- score(corpus)')
meta_corpus = r.eval_R('meta(corpus)')

i = -1
puts web_corpus.map { |article|
  i += 1
  date = r.eval_R("meta(corpus[[#{i+1}]], 'DateTimeStamp')")
  {
    url: r.eval_R("meta(corpus[[#{i+1}]], 'Origin')"),
    date: "#{date['mon']}/#{date['mday']}/#{date['year']}",
    title: r.eval_R("meta(corpus[[#{i+1}]], 'Heading')"),
    text: article.force_encoding('UTF-8'),
    polarity: meta_corpus['polarity'][i],
    subjectivity: meta_corpus['subjectivity'][i],
    pos_refs_per_ref: meta_corpus['pos_refs_per_ref'][i],
    neg_refs_per_ref: meta_corpus['neg_refs_per_ref'][i],
    senti_diffs_per_ref: meta_corpus['neg_refs_per_ref'][i]
  }
}.to_yaml
