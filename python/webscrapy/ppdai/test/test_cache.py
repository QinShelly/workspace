import sqlite3
conn = sqlite3.connect('example.db')
c = conn.cursor()
visited_link = []
for row in conn.execute("select id from ppdai"):
    visited_link.append(row[0])
print visited_link
conn.close()