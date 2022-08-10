--DATA CLEANING
select * from PortfolioProject..NashvilleHousing


--Standardize date Format 

/*select SalesDateConverted,Convert(date,SaleDate) 
from PortfolioProject..NashvilleHousing*/

Alter table NashvilleHousing
add SalesDateConverted date

update NashvilleHousing
set SalesDateConverted = CONVERT(date,SaleDate)

--populate property address data
--Always make sure to order tasks because for example, if we executed separation thing first we would not be able to do this belowed task.

select a.ParcelID,a.PropertyAddress,b.ParcelID,b.PropertyAddress
from PortfolioProject..NashvilleHousing a
join PortfolioProject..NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ]<>b.[UniqueID ] --to find out same parcelId with null address so that we can trace using Uniqueid
where a.PropertyAddress is null

--Though the property address is null in some of the rows there are ParcelID with which we can find the address
--For example, Parcelid is 025 003 and in one row the address is "xyz" but in another row it is null but the parcelId remain same for that null address
--While using join in update we have to use table alias

update a                                                   
set PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
from PortfolioProject..NashvilleHousing a
join PortfolioProject..NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ]<>b.[UniqueID ]
where a.PropertyAddress is null


--Seperating Address by Address,city and state
select PropertyAddress
from PortfolioProject..NashvilleHousing

/*
select SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress)-1)as Address,
	SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress)+1, LEN(PropertyAddress))as City
from PortfolioProject..NashvilleHousing
*/

Alter table NashvilleHousing
add SplitAddress nvarchar(255)

update NashvilleHousing
set SplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress)-1)

Alter table NashvilleHousing
add SplitCity nvarchar(255)

update NashvilleHousing
set SplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress)+1, LEN(PropertyAddress))


Select PropertyAddress,SplitAddress,SplitCity 
from PortfolioProject..NashvilleHousing

--Parsename is a split string technique which separates string by "." so we have to replace 
--"," by "." and it works backwards.


/*
select 
PARSENAME(REPLACE(OwnerAddress,',','.'),3),
PARSENAME(REPLACE(OwnerAddress,',','.'),2),
PARSENAME(REPLACE(OwnerAddress,',','.'),1)
from PortfolioProject..NashvilleHousing
*/


Alter table NashvilleHousing
add OwnerSplitAddress nvarchar(255)

update NashvilleHousing
set OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',','.'),3)

Alter table NashvilleHousing
add OwnerSplitCity nvarchar(255)

update NashvilleHousing
set OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',','.'),2)


Alter table NashvilleHousing
add OwnerSplitState nvarchar(255)

update NashvilleHousing
set OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',','.'),1)

select OwnerAddress,OwnerSplitAddress,OwnerSplitCity,OwnerSplitState
from PortfolioProject..NashvilleHousing

--Changing values (Y/N/YES/NO -> Yes/NO)
/*select distinct(SoldAsVacant),count(SoldAsVacant)
from PortfolioProject..NashvilleHousing
group by SoldAsVacant
order by 2*/

select SoldAsVacant,
	case when SoldAsVacant = 'Y' then 'Yes'
		when SoldAsVacant = 'N' then 'No'
		else SoldAsVacant
		end
from PortfolioProject..NashvilleHousing

update NashvilleHousing
set SoldAsVacant= case when SoldAsVacant = 'Y' then 'Yes'
		when SoldAsVacant = 'N' then 'No'
		else SoldAsVacant
		end

select distinct(SoldAsVacant),count(SoldAsVacant)
from PortfolioProject..NashvilleHousing
group by SoldAsVacant
order by 2

--Removing Duplicate
With DuplicateValuesCTE as(
select *,
	ROW_NUMBER() over (
	partition by ParcelID,
				PropertyAddress,
				SalePrice,
				SaleDate,
				LegalReference
				Order by UniqueID
				) row_num

from PortfolioProject..NashvilleHousing
)
/*
select * from DuplicateValuesCTE
where row_num > 1
order by PropertyAddress
*/
delete from DuplicateValuesCTE
where row_num > 1


--Removing Unused Columns

select *
from PortfolioProject..NashvilleHousing

Alter table PortfolioProject..NashvilleHousing
drop column PropertyAddress,OwnerAddress,TaxDistrict

Alter table PortfolioProject..NashvilleHousing
drop column SaleDate

