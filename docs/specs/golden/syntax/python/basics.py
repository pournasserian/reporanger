"""Conformance case for the Python syntax extractor (plugin-interface.md, sections 3 to 5)."""

import logging
from typing import overload

from .models import Order

MAX_ITEMS = 50
logger = logging.getLogger(__name__)


class Cart:
    """A shopping cart."""

    currency = "EUR"

    def __init__(self, owner: str) -> None:
        self.owner = owner
        self._items = []

    @property
    def size(self) -> int:
        return len(self._items)

    @size.setter
    def size(self, value: int) -> None:
        raise NotImplementedError

    @staticmethod
    def empty() -> "Cart":
        return Cart("")

    def add(self, item: str, quantity: int = 1) -> bool:
        if not item or quantity < 1:
            return False
        for _ in range(quantity):
            self._items.append(item)
        return True


@overload
def total(values: list) -> int: ...
@overload
def total(values: tuple) -> float: ...
def total(values):
    return sum(v for v in values if v)


if __name__ == "__main__":
    logger.info(total([1, 2]))
