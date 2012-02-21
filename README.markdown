# timeframe

A Ruby class for describing and interacting with timeframes.

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

The good parts of Timeframe all came from the gentlemen at Fingertips[http://fngtps.com].

Thanks to @artemk for https://github.com/rossmeissl/timeframe/pull/5

## Copyright

Copyright (c) 2012 Andy Rossmeissl, Seamus Abshere
