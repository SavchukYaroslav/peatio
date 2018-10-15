10.times do
  system "http POST :3000/api/v2/orders -- market=btcusd volume=1 price=1 side=sell &&  http POST :3000/api/v2/orders -- market=btcusd volume=1 price=1 side=buy"
  sleep 0.5
end
