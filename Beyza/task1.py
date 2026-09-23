# import necessary packages
from pig.utils import outputSchema
from org.apache.pig.data import DataBag, TupleFactory, BagFactory

tupleFactory = TupleFactory.getInstance()
bagFactory = BagFactory.getInstance()

@outputSchema("ranked:bag{t:(year:int, region:chararray, rank_no:int, country_code:chararray, country_name:chararray, gold:int, total_medals:int, population:long, medals_per_million:double)}")
def rank_countries(records):
    # records is a DataBag: all countries for one (year, region) group,
    # each tuple matching the schema of 'enriched' from the main script
    rows = []
    for t in records:
        year = t.get(0)
        region = t.get(1)
        country_code = t.get(2)
        country_name = t.get(3)
        gold = t.get(4)
        total_medals = t.get(5)
        population = t.get(6)
        medals_per_million = t.get(7)
        rows.append((year, region, country_code, country_name, gold, total_medals, population, medals_per_million))

    # ranking rules: medals_per_million desc, total_medals desc, gold desc, country_name asc
    rows.sort(key=lambda r: (-r[7], -r[5], -r[4], r[3]))

    for (year, region, country_code, country_name, gold, total_medals, population, medals_per_million) in rows:
        out_tuple = tupleFactory.newTuple([year, region, rank_no, country_code, country_name, gold, total_medals, population, medals_per_million])
        out_bag.add(out_tuple)
        rank_no += 1

    return out_bag
