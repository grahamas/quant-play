using Dates
using CSV
using Plots
using Statistics, HypothesisTests

function is_midterm(date::Date)
   is_midterm_year = year(date) % 4 == 2
   is_tuesday = dayname(date) == "Tuesday"
   is_firstweek_nov = (11, 1) < monthday(date) < (11,9)
   return(is_midterm_year & is_tuesday & is_firstweek_nov)
end

function is_midterm_like(date::Date)
   is_midterm_year = year(date) % 4 == 2
   is_tuesday = dayname(date) == "Tuesday"
   is_firstweek_nov = (11, 1) < monthday(date) < (11,9)
   return(is_tuesday & is_firstweek_nov & !is_midterm_year)
end

function window_percent_change(date::Date, df::DataFrame, price_sym; start=-7, stop=7)
	in_window(d) = (date + Day(start)) < d < (date + Day(stop))
	start_price, stop_price = filter(row -> in_window(row[:Date]), df)[price_sym][[1,end]]
	(stop_price - start_price) / start_price
end

function test_midterm_window(csv, start, stop; dateformat=nothing, price_sym=:Close)
	sp = CSV.read(csv, dateformat=dateformat)
	drop=5
	start_date, stop_date = sp[:Date][[1,end-drop]]
	date_range = start_date:Day(1):stop_date
	midterms = filter(is_midterm, date_range)
	controls = filter(is_midterm_like, date_range)
	midterm_changes = window_percent_change.(midterms, (sp,), price_sym, start=start, stop=stop)
	control_changes = window_percent_change.(controls, (sp,), price_sym, start=start, stop=stop)
	(EqualVarianceTTest(midterm_changes, control_changes), midterm_changes, control_changes)
end