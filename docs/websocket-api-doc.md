## Channel name "private-#{sn}"

#### Events

*order*
```ruby
{
      id:            id,  # order id
      at:            at,  # 
      market:        market_id,
      kind:          kind, # bid or ask
      price:         price&.to_s('F'),
      state:         state,
      volume:        volume.to_s('F'),
      origin_volume: origin_volume.to_s('F')
}
```


## Channel name "market-#{market.id}-global"

#### Events 

*update*


```ruby
{
  asks: [[0.4e1, 0.1e-1], [0.3e1, 0.401e1]], # first is price & second is total volume
  bids: [[0.5e1, 0.4e1]]
}
```

## Channel name "market-global"

### Events

*tickers*

```ruby
{
  name: name,
  base_unit: ask_unit,
  quote_unit: bid_unit,
  open: open,
  volume: h24_volume,
  sell: best_sell_price,
  buy: best_buy_price,
  at: at,
  low:  low,
  high: high,
  last: last
}

```
