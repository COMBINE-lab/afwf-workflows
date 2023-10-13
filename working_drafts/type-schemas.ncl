let utils = {
NumberOrNull = fun label value => 
  if std.is_number value then
    value
  else if std.to_string value == "null" then
    value
  else
    std.contract.blame_with_message "not a number or null" label,

default-k = 31,

NullOrDefaultK = fun label value =>
  if std.to_string value == "null" then 
    default-k
  else
    value,

ComputeFrom = fun label kmer_rec value =>
  if std.to_string value == "null" then
    kmer_rec.value
  else
    value,

ceil = fun val =>
  if std.number.fract val == 0 then
    std.number.truncate val
  else
    std.number.truncate ((1.0 - std.number.fract val) + val)

} in utils 
