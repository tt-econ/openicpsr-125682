import os

months = []
num_months = 12
for i in range(1, num_months+1):
    months.append(str(format(i, '02d')))

wind = "64050K"
rain = "64060K"
types = [wind, rain]
dic = {wind: "wind", rain: "rain"}

year = "2013"

newark = "EWR"
central_park = "NYC"
lga = "LGA"
jfk = "JFK"
long_island = "FRG"
stations = [newark, central_park, lga, jfk, long_island]

for type in types:
    for station in stations:
        file_name = ("../temp/" + station + "_" + dic[type] + "_" + year +
                     ".dat")
        f = open(file_name, "w")

        tempfiles = []
        for i in range(len(months)):
            filename_string = ("../external/" + type + station + year +
                               months[i] + ".dat")
            tempfiles.append(filename_string)

        for tempfile in tempfiles:
            if os.path.isfile(tempfile):
                weather_file = open(tempfile, "r")
                f.write(weather_file.read())
            else:
                print(tempfile + " does not exist.")

        f.flush()
        f.close()
