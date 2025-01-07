local lulu = {}
local csv = require("csv")
local math = require("math")

-- Helper function to fill nil values in a column with the specified method
local function fill_nil_values(column, method)
  local filled_column = {}
  local prev_value = nil
  local avg_value = 0
  local count = 0

  -- Calculate average if necessary
  if method == "average" then
    for _, value in ipairs(column) do
      if value ~= nil then
        avg_value = avg_value + value
        count = count + 1
      end
    end
    avg_value = count > 0 and (avg_value / count) or 0
  end

  -- Fill nil values based on the chosen method
  for i, value in ipairs(column) do
    if value == nil then
      if method == "previous" then
        filled_column[i] = prev_value
      elseif method == "average" then
        filled_column[i] = avg_value
      else
        filled_column[i] = 0 -- Default to 0 if no valid method is provided
      end
    else
      filled_column[i] = value
      prev_value = value
    end
  end

  return filled_column
end

-- Function to normalize a single column of data in a CSV file
function lulu.normalize_csv_column(input_file, output_file, column_index, fill_method)
  -- Check if input file exists and can be opened
  local file_handle = io.open(input_file, "r")
  if not file_handle then
    print("Error: Could not open input file.")
    return
  end
  file_handle:close()

  -- Read the CSV file and extract the specified column
  local rows = {}
  local column_values = {}
  local non_numeric_indices = {}
  local has_header = true -- Assuming the first row is a header

  for i, row in csv.rows(input_file) do
    table.insert(rows, row)
    if i == 1 and has_header then
      -- Skip the header row
    else
      local value = tonumber(row[column_index])
      if value == nil then
        table.insert(non_numeric_indices, i - (has_header and 1 or 0)) -- Adjust index for header
      else
        table.insert(column_values, value)
      end
    end
  end

  -- Report non-numeric values
  if #non_numeric_indices > 0 then
    print("Warning: Non-numeric values found at row(s): " .. table.concat(non_numeric_indices, ", "))
  end

  -- Check if the column contains any numeric values
  if #column_values == 0 then
    print("The specified column does not contain numeric values.")
    return
  end

  -- Fill nil values if specified
  if fill_method then
    column_values = fill_nil_values(column_values, fill_method)
  end

  -- Calculate min and max for normalization
  local min_val, max_val = math.huge, -math.huge
  for _, value in ipairs(column_values) do
    if value < min_val then min_val = value end
    if value > max_val then max_val = value end
  end

  -- Avoid division by zero
  if min_val == max_val then
    print("All values in the specified column are the same.")
    return
  end

  -- Normalize the column
  for i, value in ipairs(column_values) do
    column_values[i] = (value - min_val) / (max_val - min_val)
  end

  -- Write the normalized data back to the CSV file
  local file = io.open(output_file, "w")
  for i, row in ipairs(rows) do
    if i == 1 and has_header then
      -- Write header row as-is
      file:write(table.concat(row, ",") .. "\n")
    else
      -- Ensure we're writing the correct normalized value, even if there were non-numeric entries
      local norm_index = i - (has_header and 1 or 0)
      if column_values[norm_index] ~= nil then
        row[column_index] = column_values[norm_index]
      end
      file:write(table.concat(row, ",") .. "\n")
    end
  end
  file:close()

  print("Normalization complete. Output written to " .. output_file)
end

return lulu