{
NumberOrNull = fun label value => 
  if std.is_number value then
    value
  else if std.to_string value == "null" then
    value
  else
    std.contract.blame_with_message "not a number or null" label,
}
