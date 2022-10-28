
function get-recent-tga ()
{
    $date = (Get-Date).AddDays(-14).ToString('yyyy-MM-dd')

    $result = Invoke-RestMethod -Method Get -Uri ('https://api.fiscaldata.treasury.gov/services/api/fiscal_service/v1/accounting/dts/dts_table_1?filter=record_date:gte:{0},account_type:eq:Treasury General Account (TGA) Closing Balance&fields=record_date,open_today_bal' -f $date)

    # $result.data | Sort-Object -Property record_date | Select-Object -Last 1

    $result.data[-1]
}

# function get-recent-reverse-repo ()
# {
#     $result = Invoke-RestMethod 'https://markets.newyorkfed.org/api/rp/reverserepo/all/results/latest.json'
# 
#     $result.repo.operations[0]
# }

function get-recent-reverse-repo ()
{
    $result = Invoke-RestMethod 'https://markets.newyorkfed.org/api/rp/reverserepo/all/results/lastTwoWeeks.json'

    $result.repo.operations[0]
}

function get-recent-walcl ()
{
    $result = Invoke-RestMethod 'https://fred.stlouisfed.org/graph/fredgraph.csv?id=WALCL'

    ($result | ConvertFrom-Csv)[-1]
}

function get-net-liquidity ()
{
    $walcl = get-recent-walcl
    $tga = get-recent-tga
    $reverse_repo = get-recent-reverse-repo
    
    $walcl_dollars        = [decimal] $walcl.WALCL * 1000 * 1000
    $tga_dollars          = [decimal] $tga.open_today_bal * 1000 * 1000
    $reverse_repo_dollars = [decimal] $reverse_repo.totalAmtAccepted

    $walcl_dollars - $tga_dollars - $reverse_repo_dollars
}

function net-liquidity-info ()
{
    $walcl = get-recent-walcl
    $tga = get-recent-tga
    $reverse_repo = get-recent-reverse-repo
    
    $walcl_dollars        = [decimal] $walcl.WALCL * 1000 * 1000
    $tga_dollars          = [decimal] $tga.open_today_bal * 1000 * 1000
    $reverse_repo_dollars = [decimal] $reverse_repo.totalAmtAccepted

    $net_liquidity = $walcl_dollars - $tga_dollars - $reverse_repo_dollars

    $spx_fair_value = [math]::Round(($net_liquidity / 1000 / 1000 / 1000 / 1.1 - 1625), 0)

    $spx_lower_band = $spx_fair_value - 150
    $spx_upper_band = $spx_fair_value + 350 

    [pscustomobject]@{
        walcl_date = $walcl.DATE
        tga_date = $tga.record_date
        reverse_repo_date = $reverse_repo.operationDate

        walcl = $walcl_dollars
        tga   = $tga_dollars
        reverse_repo = $reverse_repo_dollars

        net_liquidity = $net_liquidity

        spx_fair_value = $spx_fair_value

        spx_lower_band = $spx_lower_band
        spx_upper_band = $spx_upper_band
    }    
}

function show-net-liquidity-info ()
{
    $result = net-liquidity-info

    'WALCL           {0} {1,20:N0}'        -f $result.walcl_date,        $result.walcl
    'TGA             {0} {1,20:N0}'        -f $result.tga_date,          $result.tga
    'REVERSE REPO    {0} {1,20:N0}'        -f $result.reverse_repo_date, $result.reverse_repo
    'NET LIQUIDITY              {0,20:N0}' -f $result.net_liquidity
    ''
    'SPX FAIR VALUE {0}' -f $result.spx_fair_value
    'SPX LOWER BAND {0}' -f $result.spx_lower_band
    'SPX UPPER BAND {0}' -f $result.spx_upper_band
}