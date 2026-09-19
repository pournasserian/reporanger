// Conformance case for the TypeScript syntax extractor (plugin-interface.md, sections 3 to 5).
import { Repository } from "./repository";
import { randomUUID } from "node:crypto";

/** A product in the catalogue. */
export class Product {
  static readonly kind = "product";
  #secret = "";
  private price = 0;

  constructor(public readonly name: string) {}

  get label(): string {
    return this.name;
  }
  set label(value: string) {
    this.price = value.length;
  }

  format(value: number): string;
  format(value: string): string;
  format(value: number | string): string {
    if (typeof value === "number" && value > 0) {
      return `${value}`;
    }
    return String(value);
  }

  readonly toId = () => randomUUID();
}

export interface Product {
  sku?: string;
}

export const makeProduct = async (name: string) => new Product(name);

export default function () {}

export enum Status {
  Draft = "draft",
  Live = "live",
}

export type ProductId = string;

namespace Legacy {
  export class Cart {}
}
