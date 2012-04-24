# timeframe

A Ruby class for describing and interacting with timeframes.

## Real-world usage

<p><a href="http://brighterplanet.com"><img src="https://s3.amazonaws.com/static.brighterplanet.com/assets/logos/flush-left/inline/green/rasterized/brighter_planet-160-transparent.png" alt="Brighter Planet logo"/></a></p>

We use `timeframe` for [data science at Brighter Planet](http://brighterplanet.com/research) and in production at

* [Brighter Planet's impact estimate web service](http://impact.brighterplanet.com)
* [Brighter Planet's reference data web service](http://data.brighterplanet.com)

Originally proposed to us by [the awesome programmers at fingertips](http:/fngtps.com)

## Based on ISO 8601

As [documented by wikipedia](http://en.wikipedia.org/wiki/ISO_8601#Time_intervals), time intervals are like:

1. Start and end, such as `2007-03-01T13:00:00Z/2008-05-11T15:30:00Z`
2. Start and duration, such as `2007-03-01T13:00:00Z/P1Y2M10DT2H30M`
3. Duration and end, such as `P1Y2M10DT2H30M/2008-05-11T15:30:00Z`
4. Duration only, such as `P1Y2M10DT2H30M`, with additional context information [not supported]

or more simply

    <start>/<end>
    <start>/<duration>
    <duration>/<end>
    <duration> [not supported]

## Precision

Currently the end result is precise to 1 day, so these are the same:

* `2007-03-01T00:00:00Z/2008-05-11T00:00:00Z`
* `2007-03-01/2008-05-11`

This may change in the future.

## Documentation

http://rdoc.info/projects/rossmeissl/timeframe

## Acknowledgements

Thanks to @artemk for https://github.com/rossmeissl/timeframe/pull/5

## Copyright

Copyright (c) 2012 Andy Rossmeissl, Seamus Abshere
