# connect to MySQL
library(RMySQL)
con <- dbConnect(dbDriver("MySQL"), user="root", "fs_beisswat")

# number of users, groups
user_count <- dbGetQuery(con, "SELECT COUNT(*) FROM users")[1,1]
# Spezial-Gruppen: Schwund (75), Gast (72), FrischeBestelldienst (61), TrockenBestelldienst (63)
group_count <- dbGetQuery(con, "SELECT COUNT(*) FROM groups WHERE type='Ordergroup' AND NOT groups.id IN (61,63,72,75)")[1,1]

# Spezial-Benutzer: admin, Gast, Schwund, FrischeBestelldienst, TrockenBestelldienst (5)
user_count <- user_count -5
#group_count <- group_count -4

# Benutzer, die sich nie / länger als X Monate nicht eingeloggt haben

# start of latest order and interval
db_date_end <- as.Date(dbGetQuery(con, "SELECT starts FROM orders ORDER BY starts DESC LIMIT 1;")[1,1])
db_date_beg <- db_date_end -99;

# Bestellgruppen, die sich im Zeitraum beteiligt haben
group_order_total <- dbGetQuery(con, sprintf("SELECT COUNT(DISTINCT name) FROM groups, group_orders, orders WHERE groups.id=group_orders.ordergroup_id AND orders.id=group_orders.order_id AND ends>='%s' AND NOT groups.id IN (61,63,72,75);", db_date_beg))[1,1]
# Anzahl Bestellgruppen pro Woche
group_order_weeks <- dbGetQuery(con, sprintf("SELECT COUNT(DISTINCT name) FROM groups, group_orders, orders WHERE groups.id=group_orders.ordergroup_id AND orders.id=group_orders.order_id AND ends>='%s' AND NOT groups.id IN (61,63,72,75) GROUP BY WEEK(ends);", db_date_beg))[,1]
group_order_weeks <- head(group_order_weeks[-1], -1)
group_order_week <- median(group_order_weeks)  # Verfahren zur Mittelwertbildung?

# Bestellgruppen, die sich im Zeitraum beteiligt haben (LAGER)
group_order_stock_total <- dbGetQuery(con, sprintf("SELECT COUNT(DISTINCT name) FROM groups, group_orders, orders WHERE groups.id=group_orders.ordergroup_id AND orders.id=group_orders.order_id AND ends>='%s' AND NOT groups.id IN (61,63,72,75) AND supplier_id=0;", db_date_beg))[1,1]
# Anzahl Bestellgruppen pro Woche (LAGER)
group_order_stock_weeks <- dbGetQuery(con, sprintf("SELECT COUNT(DISTINCT name) FROM groups, group_orders, orders WHERE groups.id=group_orders.ordergroup_id AND orders.id=group_orders.order_id AND ends>='%s' AND NOT groups.id IN (61,63,72,75) AND supplier_id=0 GROUP BY WEEK(ends);", db_date_beg))[,1]
group_order_stock_weeks <- head(group_order_stock_weeks[-1], -1)
group_order_stock_week <- median(group_order_stock_weeks)  # Verfahren zur Mittelwertbildung?

# Bestellgruppen, die sich im Zeitraum beteiligt haben (FRISCHE)
group_order_fresh_total <- dbGetQuery(con, sprintf("SELECT COUNT(DISTINCT name) FROM groups, group_orders, orders WHERE groups.id=group_orders.ordergroup_id AND orders.id=group_orders.order_id AND ends>='%s' AND NOT groups.id IN (61,63,72,75) AND supplier_id IN (4,5,6,7,20,21);", db_date_beg))[1,1]
# Anzahl Bestellgruppen pro Woche (FRISCHE)
group_order_fresh_weeks <- dbGetQuery(con, sprintf("SELECT COUNT(DISTINCT name) FROM groups, group_orders, orders WHERE groups.id=group_orders.ordergroup_id AND orders.id=group_orders.order_id AND ends>='%s' AND NOT groups.id IN (61,63,72,75) AND supplier_id IN (4,5,6,7,20,21) GROUP BY WEEK(ends);", db_date_beg))[,1]
group_order_fresh_weeks <- head(group_order_fresh_weeks[-1], -1)
group_order_fresh_week <- median(group_order_fresh_weeks)  # Verfahren zur Mittelwertbildung?


# Bestellgruppen, die sich im Zeitraum beteiligt haben
group_work_total <- dbGetQuery(con, sprintf("SELECT COUNT(DISTINCT groups.name) FROM (SELECT DISTINCT users.id FROM users, assignments, tasks WHERE users.id=assignments.user_id AND tasks.id=assignments.task_id AND tasks.updated_on>='%s') AS active_users, groups, memberships WHERE active_users.id=memberships.user_id AND groups.id=memberships.group_id AND groups.type='Ordergroup' AND NOT groups.id IN (61,63,72,75);", db_date_beg))[1,1]
# Anzahl Bestellgruppen pro Woche
group_work_weeks <- dbGetQuery(con, sprintf("SELECT COUNT(DISTINCT groups.name) FROM (SELECT users.id, tasks.updated_on FROM users, assignments, tasks WHERE users.id=assignments.user_id AND tasks.id=assignments.task_id AND tasks.updated_on>='%s') AS active_users, groups, memberships WHERE active_users.id=memberships.user_id AND groups.id=memberships.group_id AND groups.type='Ordergroup' AND NOT groups.id IN (61,63,72,75) GROUP BY WEEK(active_users.updated_on);", db_date_beg))[,1]
group_work_weeks <- head(group_work_weeks[-1], -1)
group_work_week <- median(group_work_weeks)  # Verfahren zur Mittelwertbildung?


out <- function(str, arg=0) { cat(sprintf(str, arg)) }

out("Benutzer gesamt: %d\n", user_count)
out("Bestellgruppen: %d\n", group_count)
out("\n")
out("Zeitraum (grob): %s", db_date_beg); out(" - %s\n", db_date_end)
out("\n")
out("--------------------------------------------------------------\n")
out("\n")
out("Bestellgruppen, die eingekauft/bestellt haben: %d\n", group_order_total)
out("-> das sind %.0f%% aller Gruppen\n", group_order_total/group_count*100)
out("Bestellgruppen pro Woche: %.1f", group_order_week); out("  (%s)\n",paste(sort(group_order_weeks), collapse=","))
out("-> das sind %.0f%% aller Gruppen\n", group_order_week/group_count*100)
out("-> das sind %.0f%% der Gruppen, die insgesamt bestellt/eingekauft haben\n", group_order_week/group_order_total*100)
out("\n")
out("Bestellgruppen, die gearbeitet haben (mindestens ein Mitglied): %d\n", group_work_total)
out("-> das sind %.0f%% aller Gruppen\n", group_work_total/group_count*100)
out("-> das sind %.0f%% der Gruppen, die insgesamt bestellt/eingekauft haben\n", group_work_total/group_order_total*100)
out("Bestellgruppen pro Woche: %.1f", group_work_week); out("  (%s)\n",paste(sort(group_work_weeks), collapse=","))
out("-> das sind %.0f%% aller Gruppen\n", group_work_week/group_count*100)
out("-> das sind %.0f%% der Gruppen, die insgesamt gearbeitet haben\n", group_work_week/group_work_total*100)
out("-> das sind %.0f%% der Gruppen, die insgesamt bestellt/eingekauft haben\n", group_work_week/group_order_total*100)
out("-> das sind %.0f%% der Gruppen, die wöchentlich bestellt/eingekauft haben\n", group_work_week/group_order_week*100)
out("\n")
out("--------------------------------------------------------------\n")
out("\n")
out("Bestellgruppen, die im Lager eingekauft haben: %d\n", group_order_stock_total)
out("-> das sind %.0f%% aller Gruppen\n", group_order_stock_total/group_count*100)
out("-> das sind %.0f%% der Gruppen, die bestellt/eingekauft haben\n", group_order_stock_total/group_order_total*100)
out("Bestellgruppen pro Woche: %.1f", group_order_stock_week); out("  (%s)\n",paste(sort(group_order_stock_weeks), collapse=","))
out("-> das sind %.0f%% aller Gruppen\n", group_order_stock_week/group_count*100)
out("-> das sind %.0f%% der Gruppen, die insgesamt bestellt/eingekauft haben\n", group_order_stock_week/group_order_total*100)
out("-> das sind %.0f%% der Gruppen, die insgesamt im Lager eingekauft haben\n", group_order_stock_week/group_order_stock_total*100)
out("\n")
out("Bestellgruppen, die Frischesachen bestellt haben: %d\n", group_order_fresh_total)
out("-> das sind %.0f%% aller Gruppen\n", group_order_fresh_total/group_count*100)
out("-> das sind %.0f%% der Gruppen, die bestellt/eingekauft haben\n", group_order_fresh_total/group_order_total*100)
out("Bestellgruppen pro Woche: %.1f", group_order_fresh_week); out("  (%s)\n",paste(sort(group_order_fresh_weeks), collapse=","))
out("-> das sind %.0f%% aller Gruppen\n", group_order_fresh_week/group_count*100)
out("-> das sind %.0f%% der Gruppen, die insgesamt bestellt/eingekauft haben\n", group_order_fresh_week/group_order_total*100)
out("-> das sind %.0f%% der Gruppen, die insgesamt Frischesachen bestellt haben\n", group_order_fresh_week/group_order_fresh_total*100)
